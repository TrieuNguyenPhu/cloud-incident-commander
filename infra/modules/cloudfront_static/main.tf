resource "aws_s3_bucket" "web" {
  #checkov:skip=CKV_AWS_18:Access-log destination and retention require a separate privacy and cost review.
  #checkov:skip=CKV_AWS_144:This dev frontend is single-region by ADR-018; replication adds cost and a second stateful bucket.
  #checkov:skip=CKV_AWS_145:ADR-001 allows SSE-S3; KMS key lifecycle and cost need a separate decision.
  #checkov:skip=CKV2_AWS_62:Static assets have no event-driven consumer.
  bucket_prefix = "cic-${var.environment}-web-"
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket                  = aws_s3_bucket.web.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "web" {
  bucket = aws_s3_bucket.web.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  rule {
    id     = "bound-static-asset-retention"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_cloudfront_origin_access_control" "web" {
  name                              = "cic-${var.environment}-web"
  description                       = "Private S3 origin for the CIC static web export"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "static_routes" {
  name    = "cic-${var.environment}-static-routes"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-JS
    function handler(event) {
      var request = event.request;
      if (request.uri.endsWith("/")) request.uri += "index.html";
      return request;
    }
  JS
  tags    = var.tags
}

resource "aws_cloudfront_distribution" "web" {
  #checkov:skip=CKV_AWS_174:Default CloudFront certificate is configured for TLSv1.2_2021 below.
  #checkov:skip=CKV_AWS_310:One private S3 origin is sufficient for this dev static site; no failover origin is provisioned.
  #checkov:skip=CKV_AWS_374:The product has no geographic access restriction requirement.
  #checkov:skip=CKV_AWS_68:WAF is outside P1-01 and adds ongoing cost; review before exposing authenticated workflows.
  #checkov:skip=CKV_AWS_86:Access-log destination and retention require a separate privacy and cost review.
  #checkov:skip=CKV2_AWS_42:No custom domain or ACM certificate is configured in P1-01.
  #checkov:skip=CKV2_AWS_47:WAF is not attached; see CKV_AWS_68 rationale.
  #checkov:skip=CKV2_AWS_72:S3 REST origins use HTTPS with OAC and have no custom-origin protocol policy.
  #checkov:skip=CKV2_AWS_32:The AWS-managed SecurityHeadersPolicy is attached by ID; Checkov does not resolve managed IDs.
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  tags                = var.tags

  origin {
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id                = "private-s3-web"
    origin_access_control_id = aws_cloudfront_origin_access_control.web.id
  }

  default_cache_behavior {
    target_origin_id           = "private-s3-web"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.static_routes.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web.arn}/*"
        Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.web.arn } }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.web.arn, "${aws_s3_bucket.web.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}

output "bucket_name" {
  value = aws_s3_bucket.web.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.web.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.web.id
}
