mock_provider "aws" {}

variables {
  bucket_name       = "cic-state-test-example"
  owner_tag         = "test-owner"
  budget_email      = "owner@example.com"
  budget_limit_usd  = 25
  backend_role_arns = ["arn:aws:iam::111122223333:role/cic-state-test"]
}

run "encrypted_private_versioned_state_and_alerts" {
  command = plan
  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "State must be versioned."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "State must be encrypted."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "All four public access blocks must be enabled."
  }
  assert {
    condition     = !aws_s3_bucket.state.force_destroy && aws_s3_bucket.state.tags.owner == "test-owner"
    error_message = "State must retain data and identify its owner."
  }
  assert {
    condition     = toset([for alert in aws_budgets_budget.core.notification : alert.threshold]) == toset([50, 80, 100])
    error_message = "Budget notifications must cover 50%, 80% and 100%."
  }
  assert {
    condition     = aws_budgets_budget.core.limit_amount == "25" && alltrue([for alert in aws_budgets_budget.core.notification : contains(alert.subscriber_email_addresses, "owner@example.com")])
    error_message = "Budget must have the reviewed threshold and notification recipient."
  }
}

run "wildcard_backend_role_is_rejected" {
  command = plan
  variables {
    backend_role_arns = ["arn:aws:iam::111122223333:role/*"]
  }
  expect_failures = [var.backend_role_arns]
}

run "missing_owner_is_rejected" {
  command = plan
  variables {
    owner_tag = "UNCONFIGURED"
  }
  expect_failures = [var.owner_tag]
}

run "invalid_budget_recipient_is_rejected" {
  command = plan
  variables {
    budget_email = "invalid"
  }
  expect_failures = [var.budget_email]
}
