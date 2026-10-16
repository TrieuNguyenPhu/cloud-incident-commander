mock_provider "aws" {}

run "bootstrap_is_opt_in" {
  command = plan
  assert {
    condition     = !var.provision_bootstrap && length(module.backend) == 0
    error_message = "Bootstrap must create no resources by default."
  }
}

run "other_region_is_rejected" {
  command = plan
  variables {
    aws_region = "ap-southeast-1"
  }
  expect_failures = [var.aws_region]
}
