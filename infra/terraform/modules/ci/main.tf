data "aws_caller_identity" "current" {}

resource "random_id" "id" {
  byte_length = 4
}

locals {
  bucket_name = "${var.project_name}-artifacts-${random_id.id.hex}"

  # Attempt to derive default OIDC provider ARN if not supplied
  derived_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"

  github_subjects = [
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*",
    "repo:${var.github_org}/${var.github_repo}:pull_request"
  ]
}

resource "aws_s3_bucket" "artifacts" {
  bucket = local.bucket_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "artifacts"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    id     = "expire-artifacts"
    status = "Enabled"
    expiration {
      days = var.bucket_expiration_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "ci_assume" {
  dynamic "statement" {
    for_each = (var.oidc_provider_arn != null ? [1] : [1])
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals {
        type        = "Federated"
        identifiers = [coalesce(var.oidc_provider_arn, local.derived_oidc_provider_arn)]
      }
      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = local.github_subjects
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_aws_principals) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = var.allowed_aws_principals
      }
    }
  }
}

resource "aws_iam_role" "ci_role" {
  name               = "${var.project_name}-ci-role"
  assume_role_policy = data.aws_iam_policy_document.ci_assume.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "ci_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ci_policy" {
  name   = "${var.project_name}-ci-policy"
  policy = data.aws_iam_policy_document.ci_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ci_role.name
  policy_arn = aws_iam_policy.ci_policy.arn
}
