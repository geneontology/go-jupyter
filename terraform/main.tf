# Stable random suffix scoped to (project, environment). Persisted in
# state across normal applies — only rotates when var.environment changes
# (or an operator explicitly bumps the keepers). The suffix lets two
# operators both run with environment="test" without colliding on
# user-namespace resource names (key pair, SG), and lets a responder group
# AWS resources by Deployment tag to see one logical stack at a time.
resource "random_id" "deployment" {
  byte_length = 4
  keepers = {
    environment = var.environment
  }
}

locals {
  deployment = "${var.environment}-${random_id.deployment.hex}" # e.g. "test-a1b2c3d4"
  name       = "go-jupyter-${local.deployment}"                 # e.g. "go-jupyter-test-a1b2c3d4"

  # Auto-rolling hostname during iteration; explicit override for a stable
  # cutover. The auto form embeds random_id.deployment.hex so every
  # destroy+apply cycle gets a fresh DNS name (and, with per-host certs, a
  # fresh LE cert, avoiding the 5/week duplicate-cert limit). Same
  # `terraform apply` against existing state keeps the same hostname because
  # the suffix is persisted in state.
  hostname = coalesce(
    var.hostname_override,
    "${var.hostname_prefix}-${random_id.deployment.hex}.${var.route53_zone_name}",
  )

  # Domain whose cert lives at live/<domain>/ in the S3 bundle; defaults to the zone.
  cert_domain = var.cert_domain != "" ? var.cert_domain : var.route53_zone_name

  tags = merge(
    {
      Project      = "go-jupyter"
      Environment  = var.environment
      Deployment   = local.deployment
      Name         = local.name
      ManagedBy    = "terraform"
      Repo         = "geneontology/go-jupyter"
      ContactEmail = var.acme_email
    },
    var.tags,
  )
}

# Attach to an existing VPC/subnet selected by Name tag.
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_tag]
  }
}

data "aws_subnet" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.subnet_name_tag]
  }
}

# Canonical Ubuntu 24.04 LTS (Noble), amd64, hvm-ssd.
data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = local.name
  public_key = trimspace(file(var.ssh_public_key_path))
  tags       = local.tags
}

# Cloudflare's edge ranges, read at plan time when web_ingress = "cloudflare".
# A non-200 answer fails the plan rather than producing an empty allow list.
data "http" "cloudflare_ips_v4" {
  count = var.web_ingress == "cloudflare" ? 1 : 0
  url   = "https://www.cloudflare.com/ips-v4"

  retry {
    attempts = 2
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "https://www.cloudflare.com/ips-v4 did not answer 200; refusing to plan a security group that could lock the edge out."
    }
  }
}

locals {
  # One CIDR per line; anything that is not a valid IPv4 prefix is dropped.
  cloudflare_ipv4 = var.web_ingress == "cloudflare" ? [
    for line in split("\n", data.http.cloudflare_ips_v4[0].response_body) :
    trimspace(line) if can(cidrnetmask(trimspace(line)))
  ] : []
  web_cidrs_443 = var.web_ingress == "cloudflare" ? local.cloudflare_ipv4 : var.allowed_web_cidrs
}

resource "aws_security_group" "this" {
  name        = local.name
  description = "go-jupyter ${local.deployment}"
  vpc_id      = data.aws_vpc.this.id
  tags        = local.tags

  lifecycle {
    precondition {
      condition     = var.web_ingress != "cloudflare" || var.fronting == "cloudflare"
      error_message = "web_ingress = \"cloudflare\" admits only Cloudflare's edge on 443, which makes sense only with fronting = \"cloudflare\"."
    }
    precondition {
      condition     = var.web_ingress != "cloudflare" || length(local.cloudflare_ipv4) >= 10
      error_message = "Cloudflare's IPv4 list parsed to fewer than 10 ranges (it has had 15 for years); refusing to plan an allow list that could lock the edge out."
    }
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Port 80 exists only in the open shape; a Cloudflare-fronted origin is
  # spoken to on 443 alone and does no ACME HTTP-01.
  dynamic "ingress" {
    for_each = var.web_ingress == "cidrs" ? [1] : []
    content {
      description = "http (Caddy / ACME HTTP-01 challenge)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.allowed_web_cidrs
    }
  }

  ingress {
    description = var.web_ingress == "cloudflare" ? "https from Cloudflare edge ranges only (ips-v4 read at plan time)" : "https (Caddy reverse proxy to JupyterHub)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.web_cidrs_443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM role for the instance. When wildcard_cert_s3_uri is set, it also gets a
# read-only policy to fetch that cert bundle from S3 at boot, so the private
# key never lives in Terraform state or user_data.
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "cert_read" {
  count = var.wildcard_cert_s3_uri != "" ? 1 : 0
  name  = "wildcard-cert-read"
  role  = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${replace(var.wildcard_cert_s3_uri, "s3://", "")}"
    }]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name = local.name
  role = aws_iam_role.instance.name
  tags = local.tags
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = data.aws_subnet.this.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gb
    encrypted   = true
    # EC2 does not copy instance tags onto the root volume; without this the
    # disk is untagged (no Project, no Name) in billing and tag-based queries.
    tags = local.tags
  }

  # gzip+base64 the cloud-init script: EC2 caps raw user_data at 16 KiB, which
  # the plaintext script (deploy key + API key + the full provisioning body)
  # exceeds. cloud-init auto-detects the gzip magic and decompresses.
  user_data_base64 = base64gzip(templatefile("${path.module}/user_data.sh.tpl", {
    git_repo_ssh_url           = var.git_repo_ssh_url
    git_ref                    = var.git_ref
    backend                    = var.backend
    anthropic_api_key          = var.anthropic_api_key_path != "" ? trimspace(file(var.anthropic_api_key_path)) : ""
    gcp_credentials_json       = var.gcp_credentials_json_path != "" ? file(var.gcp_credentials_json_path) : ""
    deploy_key_private         = var.deploy_key_private_path != "" ? file(var.deploy_key_private_path) : ""
    langfuse_env               = var.langfuse_env_path != "" ? trimspace(file(var.langfuse_env_path)) : ""
    hostname                   = local.hostname
    wildcard_cert_s3_uri       = var.wildcard_cert_s3_uri
    cert_domain                = local.cert_domain
    local_users                = var.local_users
    github_oauth_client_id     = var.github_oauth_client_id
    github_oauth_client_secret = var.github_oauth_client_secret
    allowlist_authorization    = var.allowlist_authorization
    reset_days                 = var.reset_days
  }))

  # Re-run user_data when its inputs change. Changing git_ref / tokens /
  # hostname triggers an instance replacement.
  user_data_replace_on_change = true

  # GUARD — an instance replacement destroys the root EBS and every /home on it.
  # Curators' working directories live on this box with no standing backup, so a
  # replacement is real data loss, not a redeploy.
  #
  # The trap is that replacement is easy to trigger by accident: any change to
  # user_data / git_ref / a token / the hostname flips the plan from "update in
  # place" to "destroy and recreate". prevent_destroy turns that into a hard
  # error instead of a silent wipe.
  #
  # ignore_changes covers the two inputs that only matter at first boot and
  # drift on their own: the AMI lookup moves whenever Canonical publishes a new
  # image, and user_data changes with every edit to user_data.sh.tpl. Neither
  # can be applied to a running box (cloud-init runs once), so tracking them
  # only made every plan a replacement, which prevent_destroy turns into an
  # error, which left no way to apply in-place changes (tags, volume size)
  # without -target. New boxes still get the current AMI and template.
  #
  # To do a genuine rebuild: bring up a second stack from its own state and
  # migrate (blue/green, see README), or comment this block out, apply, and put
  # it back. Port the users first with `sudo go-jupyter-migrate <old-host>`.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ami, user_data_base64]
  }

  tags = local.tags
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id
  tags     = local.tags
}

# Public DNS — independent of instance lifecycle so it survives replacements.
data "aws_route53_zone" "this" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  # 'direct' fronting only. Under 'cloudflare' the hostname is a CDN CNAME
  # whose origin (a CDN-side A record) is managed out-of-band, so we create
  # no Route53 A record here.
  count   = var.fronting == "direct" ? 1 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.hostname
  type    = "A"
  ttl     = 60
  records = [aws_eip.this.public_ip]
}
