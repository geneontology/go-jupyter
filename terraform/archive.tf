# Off-box copy of the transcript archive (#124).
#
# /var/lib/go-jupyter/traces is the hub's only full record of what curators and
# their agents did (Langfuse shows a window of it), and until this bucket
# existed its one copy was the instance's root disk. go-jupyter-trace-offsite
# copies it here every night.
#
# The bucket is private (no public access of any kind), versioned and never
# expires anything. Readers are whoever the account's own IAM permissions let
# read S3: these are working records for the people improving the system, not
# secrets, and not public. The box itself may only add: it can list and upload,
# and can neither read an object back nor delete one or a version of one, so a
# compromised hub cannot read or erase the copy.
#
# Nothing here is created when trace_archive_bucket is empty.

locals {
  trace_archive = var.trace_archive_bucket != ""
}

resource "aws_s3_bucket" "trace_archive" {
  count  = local.trace_archive ? 1 : 0
  bucket = var.trace_archive_bucket
  tags   = local.tags

  # The bucket outlives the instance on purpose: it is what a rebuild restores
  # from. Removing it is a decision made by hand, not by a plan.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "trace_archive" {
  count                   = local.trace_archive ? 1 : 0
  bucket                  = aws_s3_bucket.trace_archive[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "trace_archive" {
  count  = local.trace_archive ? 1 : 0
  bucket = aws_s3_bucket.trace_archive[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# A transcript is appended to for as long as its session lives, and each
# nightly upload of a grown file keeps the one before it as a version. An
# overwrite or a delete marker therefore loses nothing.
resource "aws_s3_bucket_versioning" "trace_archive" {
  count  = local.trace_archive ? 1 : 0
  bucket = aws_s3_bucket.trace_archive[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trace_archive" {
  count  = local.trace_archive ? 1 : 0
  bucket = aws_s3_bucket.trace_archive[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# The only lifecycle rule removes the parts of uploads that never completed.
# No object and no version is ever expired.
resource "aws_s3_bucket_lifecycle_configuration" "trace_archive" {
  count  = local.trace_archive ? 1 : 0
  bucket = aws_s3_bucket.trace_archive[0].id
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  depends_on = [aws_s3_bucket_versioning.trace_archive]
}

data "aws_iam_policy_document" "trace_archive_tls" {
  count = local.trace_archive ? 1 : 0
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.trace_archive[0].arn,
      "${aws_s3_bucket.trace_archive[0].arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "trace_archive" {
  count      = local.trace_archive ? 1 : 0
  bucket     = aws_s3_bucket.trace_archive[0].id
  policy     = data.aws_iam_policy_document.trace_archive_tls[0].json
  depends_on = [aws_s3_bucket_public_access_block.trace_archive]
}

# What the box may do: see which keys exist (so the nightly sync uploads only
# what changed) and add objects. No GetObject, no DeleteObject, no
# DeleteObjectVersion, no change to the bucket's configuration.
resource "aws_iam_role_policy" "trace_archive_write" {
  count = local.trace_archive ? 1 : 0
  name  = "trace-archive-write"
  role  = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListArchive"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.trace_archive[0].arn
      },
      {
        Sid      = "AddToArchive"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:AbortMultipartUpload"]
        Resource = "${aws_s3_bucket.trace_archive[0].arn}/*"
      },
    ]
  })
}
