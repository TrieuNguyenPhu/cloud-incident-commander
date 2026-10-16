mock_provider "aws" {}

variables {
  environment = "dev"
  tags = {
    project     = "cic"
    environment = "dev"
    owner       = "test-owner"
    managed_by  = "terraform"
    expires_at  = "persistent"
  }
}

run "private_static_site_mock_apply" {
  command = apply

  assert {
    condition     = aws_s3_bucket.web.force_destroy == false
    error_message = "Destroying the static site must not delete uploaded assets."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.web.block_public_acls && aws_s3_bucket_public_access_block.web.block_public_policy && aws_s3_bucket_public_access_block.web.ignore_public_acls && aws_s3_bucket_public_access_block.web.restrict_public_buckets
    error_message = "The static asset bucket must block all public access."
  }
  assert {
    condition     = length([for origin in aws_cloudfront_distribution.web.origin : origin if origin.origin_access_control_id == aws_cloudfront_origin_access_control.web.id]) == 1
    error_message = "CloudFront must access S3 through OAC."
  }
  assert {
    condition     = aws_cloudfront_distribution.web.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "The site must redirect viewers to HTTPS."
  }
  assert {
    condition     = output.distribution_domain_name != ""
    error_message = "The module must expose the CloudFront domain for the static site."
  }
}
