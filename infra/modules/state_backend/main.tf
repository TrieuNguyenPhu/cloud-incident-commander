resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_18:State access logging destination is deferred; CloudTrail data events must be reviewed before AWS apply.
  #checkov:skip=CKV_AWS_144:Single-region dev baseline; cross-region replication is outside ADR-001.
  #checkov:skip=CKV_AWS_145:ADR-001/NFR-006 allow SSE-S3; KMS cost and key lifecycle require separate review.
  #checkov:skip=CKV2_AWS_62:No event-driven consumer for the Terraform state bucket.
  bucket        = var.bucket_name
  force_destroy = false
  tags = {
    project     = "cic"
    environment = "dev"
    owner       = var.owner_tag
    managed_by  = "terraform"
    expires_at  = "persistent"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "RestrictStateDataToReviewedRoles"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = var.backend_role_arns } }
      }
    ]
  })
}

resource "aws_budgets_budget" "core" {
  name         = "cic-dev-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  dynamic "notification" {
    for_each = toset([50, 80, 100])
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.budget_email]
    }
  }
  tags = {
    project     = "cic"
    environment = "dev"
    owner       = var.owner_tag
    managed_by  = "terraform"
    expires_at  = "persistent"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.state.id
}
