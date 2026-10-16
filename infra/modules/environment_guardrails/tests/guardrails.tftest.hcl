variables {
  environment = "lab"
  is_lab      = true
}

run "disabled_needs_no_account_configuration" {
  command = plan
}

run "other_region_is_rejected" {
  command = plan
  variables {
    aws_region = "ap-southeast-1"
  }
  expect_failures = [var.aws_region]
}

run "enabled_lab_requires_an_owner" {
  command = plan
  variables {
    enabled        = true
    lab_expires_at = timeadd(timestamp(), "1h")
  }
  expect_failures = [var.owner_tag]
}

run "enabled_lab_requires_expiry" {
  command = plan
  variables {
    enabled   = true
    owner_tag = "test-owner"
  }
  expect_failures = [var.lab_expires_at]
}

run "expired_lab_is_rejected" {
  command = plan
  variables {
    enabled        = true
    owner_tag      = "test-owner"
    lab_expires_at = "2020-01-01T00:00:00Z"
  }
  expect_failures = [var.lab_expires_at]
}

run "valid_lab_tags" {
  command = plan
  variables {
    enabled        = true
    owner_tag      = "test-owner"
    lab_expires_at = timeadd(timestamp(), "1h")
  }
  assert {
    condition     = output.tags.owner == "test-owner" && output.tags.environment == "lab" && output.tags.expires_at != null
    error_message = "Enabled labs need owner, lab environment and TTL tags."
  }
}

run "overlong_lab_is_rejected" {
  command = plan
  variables {
    enabled        = true
    owner_tag      = "test-owner"
    lab_expires_at = timeadd(timestamp(), "8h")
  }
  expect_failures = [var.lab_expires_at]
}
