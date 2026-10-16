mock_provider "aws" {}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = !var.enable_elk_lab
    error_message = "Cloud resources must remain opt-in."
  }
  assert {
    condition     = output.planned_tags.project == "cic"
    error_message = "Project tags must not drift."
  }
}

run "unimplemented_phase_fails_closed" {
  command = plan
  variables {
    owner_tag      = "test-owner"
    lab_expires_at = timeadd(timestamp(), "1h")
    enable_elk_lab = true
  }
  expect_failures = [var.enable_elk_lab]
}
