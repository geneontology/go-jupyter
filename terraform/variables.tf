variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_name_tag" {
  description = "Name tag of the existing VPC to deploy into."
  type        = string
  default     = "default"
}

variable "subnet_name_tag" {
  description = "Name tag of the public subnet to launch the instance in. Must be in the VPC selected by vpc_name_tag."
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Short human-readable label for this deployment (e.g. test, prod, dev). Combined with a random suffix to form the per-deployment Name tag and the user-namespace names of the key pair and security group. The random suffix lets two operators share a label without colliding."
  type        = string
  default     = "test"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,15}$", var.environment))
    error_message = "environment must be 1-16 chars, lowercase alphanumeric or hyphen, starting with a letter."
  }
}

variable "instance_type" {
  description = "EC2 instance type. A few users each running Claude Code (Node) plus JupyterLab is memory-bound; size for RAM. A memory-optimized type with swap is recommended for multi-user use."
  type        = string
  default     = "t3.large"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 100
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to install on the instance."
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to reach SSH (22). The default is open for first bring-up; tighten to a known CIDR before sharing the URL."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# The hub listens on 127.0.0.1:8000 only; the public ports are 80 and 443,
# where Caddy terminates TLS and reverse-proxies to it. See allowed_web_cidrs.

variable "allowed_web_cidrs" {
  description = "CIDR blocks allowed to reach the public web ports (80, 443) where Caddy terminates TLS and reverse-proxies to JupyterHub on localhost:8000."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "hostname_prefix" {
  description = "Subdomain prefix for the rolling iteration hostname. Combined with the random deployment suffix and route53_zone_name to form a unique hostname per destroy+apply cycle, e.g. 'jupyter-test-d5d48e4b.example.org'. A fresh name each cycle avoids Let's Encrypt's 5/week duplicate-cert limit."
  type        = string
  default     = "jupyter-test"
}

variable "hostname_override" {
  description = "If set, used verbatim as the public hostname (must be a fully-qualified name under route53_zone_name). Use this for a stable cutover, e.g. 'jupyter.example.org'. Leave null during iteration to get an auto-rolling hostname."
  type        = string
  default     = null
}

variable "route53_zone_name" {
  description = "Required. Public Route53 hosted zone the hostname lives under, set to a zone you control (e.g. 'example.org'; GO production uses 'geneontology.io'). No default: you must supply it."
  type        = string
}

variable "acme_email" {
  description = "Contact email used as the ContactEmail resource tag."
  type        = string
  default     = ""
}

# Do NOT put Caddy's basic_auth in front of JupyterHub: it renders JupyterLab as
# a blank screen after login — some of JupyterLab's fetch() / web-worker /
# WebSocket-upgrade requests don't replay the cached basic-auth credential and
# the upstream 401s silently. Solve that propagation issue first, or the lab
# breaks.

variable "git_repo_ssh_url" {
  description = "Git URL of the repo cloned onto the instance at boot (the deployment source). Defaults to this public repo over HTTPS (no deploy key needed); point it at your own fork to deploy your own skills/templates. Use an SSH URL plus deploy_key_private_path only if your source repo is private."
  type        = string
  default     = "https://github.com/geneontology/go-jupyter.git"
}

variable "git_ref" {
  description = "Branch, tag, or commit to check out."
  type        = string
  default     = "main"
}

variable "deploy_key_private_path" {
  description = "Path on the operator's machine to the private half of a read-only GitHub deploy key for git_repo_ssh_url, used when the source repo is private. Read at plan time and baked into user_data; never committed. Leave empty when cloning a public repo over HTTPS."
  type        = string
  default     = ""
}

variable "gcp_credentials_json_path" {
  description = "Path on the operator's machine to the GCP service account JSON key for the Vertex AI consumer SA. Only needed when backend = \"vertex\". Read at plan time via file() and baked into user_data; never committed. Cloud-init writes the contents to /etc/gcp-credentials.json on the box. Leave empty for the 'anthropic' backend."
  type        = string
  default     = ""
}

variable "backend" {
  description = "Model/provider backend Claude Code uses: 'anthropic' (first-party Claude API, using anthropic_api_key_path) or 'vertex' (Anthropic models on Vertex AI, using gcp_credentials_json_path). Delivered to the box at /etc/default/go-jupyter and read by the hub at startup; can also be flipped in place for testing (edit that file + `systemctl restart jupyterhub`)."
  type        = string
  default     = "anthropic"
  validation {
    condition     = contains(["anthropic", "vertex"], var.backend)
    error_message = "backend must be 'anthropic' or 'vertex'."
  }
}

variable "anthropic_api_key_path" {
  description = "Path on the operator's machine to a file containing the first-party Claude API key for the 'anthropic' backend. Only needed when backend = \"anthropic\" (the default). Read at plan time via file() and baked into user_data; the key value never lives in tfvars. Cloud-init writes the contents to /etc/anthropic-api-key (mode 0600). Leave empty when backend = 'vertex'."
  type        = string
  default     = ""
}

variable "local_users" {
  description = "Out-of-band local accounts created on the box at boot for the PAM (Tier B) authenticator. Each entry is created via useradd + chpasswd and added to /etc/jupyterhub/local_users.txt so PAMAuthenticator allows it; the home is seeded on first login by the spawner from the user's chosen starter template. Operators can also add users at runtime via `sudo go-jupyter-add-user <name>`. Sensitive: lives in terraform.tfvars (gitignored), terraform.tfstate, and the rendered user_data. Leave as [] to deploy with no OOB accounts."
  type = list(object({
    username = string
    password = string
  }))
  default   = []
  sensitive = true
}

variable "github_oauth_client_id" {
  description = "GitHub OAuth App Client ID for the GitHubOAuthenticator (Tier A). Not sensitive (public identifier). Leave empty to deploy with the OAuth tier disabled — only Tier B (PAM) will be available on the login page."
  type        = string
  default     = ""
}

variable "github_oauth_client_secret" {
  description = "GitHub OAuth App Client Secret. Sensitive: lives in terraform.tfvars (gitignored), terraform.tfstate, and the rendered user_data. Pair with github_oauth_client_id to enable Tier A."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Extra tags merged into the standard tag set on all resources. The standard tags are Project, Environment, Deployment, Name, ManagedBy, Repo, ContactEmail."
  type        = map(string)
  default     = {}
}

variable "fronting" {
  description = "How the box is fronted. 'direct' (test/rolling): Terraform creates a Route53 A record for the hostname -> EIP; the box is reachable directly. 'cloudflare' (behind a CDN/WAF): no Route53 A record is created -- the hostname is a CDN CNAME whose proxied origin points at the EIP, managed out-of-band. In BOTH modes the box serves the wildcard cert on :443."
  type        = string
  default     = "direct"
  validation {
    condition     = contains(["direct", "cloudflare"], var.fronting)
    error_message = "fronting must be 'direct' or 'cloudflare'."
  }
}

variable "wildcard_cert_s3_uri" {
  description = "Required. S3 URI of a wildcard-cert bundle (a certbot tree, tar.gz) the box fetches at boot via its IAM role, so the private key never lives in Terraform state or user_data. Supply a bundle in a bucket you control, e.g. s3://your-bucket/your-domain.tar.gz (GO production uses s3://go-service-lockbox/<domain>.tar.gz). The bundle must contain live/<cert_domain>/{fullchain,privkey}.pem. Per-host Let's Encrypt is not wired in this version."
  type        = string
}

variable "cert_domain" {
  description = "The domain whose cert lives at live/<cert_domain>/ inside the wildcard_cert_s3_uri bundle. Defaults to route53_zone_name when left empty."
  type        = string
  default     = ""
}
