mock_provider "aws" {}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = !var.create_core
    error_message = "Cloud resources must remain opt-in."
  }
  assert {
    condition     = output.planned_tags.project == "cic"
    error_message = "Project tags must not drift."
  }
}

run "web_stack_mock_apply" {
  command = apply
  variables {
    owner_tag   = "test-owner"
    create_core = true
  }
  assert {
    condition     = output.web_bucket_name != null && output.web_distribution_domain_name != null
    error_message = "The enabled core stack must expose the private static site."
  }
}
