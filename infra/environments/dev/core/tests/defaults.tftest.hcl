mock_provider "aws" {}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = !var.create_core && length(module.web) == 0
    error_message = "Cloud resources must remain opt-in."
  }
  assert {
    condition     = output.planned_tags.project == "cic"
    error_message = "Project tags must not drift."
  }
}

run "web_stack_opt_in_plan" {
  command = plan
  variables {
    owner_tag   = "test-owner"
    create_core = true
  }
  assert {
    condition     = length(module.web) == 1
    error_message = "The enabled core stack must expose the private static site."
  }
}
