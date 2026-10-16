provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.aws_account_id == null ? null : [var.aws_account_id]
  default_tags {
    tags = {
      project     = "cic"
      environment = "dev"
      owner       = var.owner_tag
      managed_by  = "terraform"
      expires_at  = "persistent"
    }
  }
}

module "backend" {
  count  = var.provision_bootstrap ? 1 : 0
  source = "../modules/state_backend"

  bucket_name       = var.state_bucket_name
  owner_tag         = var.owner_tag
  budget_email      = var.budget_email
  budget_limit_usd  = var.core_budget_alert_usd
  backend_role_arns = var.backend_role_arns
}

output "state_bucket_name" {
  value = var.provision_bootstrap ? module.backend[0].bucket_name : null
}
