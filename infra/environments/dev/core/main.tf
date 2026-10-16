variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "create_core" {
  type    = bool
  default = false
  validation {
    condition     = !var.create_core
    error_message = "P1 resources are not implemented in P0. Keep this flag false until that phase is reviewed."
  }
}

variable "owner_tag" {
  type    = string
  default = "UNCONFIGURED"
}

module "guardrails" {
  aws_region  = var.aws_region
  source      = "../../../modules/environment_guardrails"
  environment = "dev"
  is_lab      = false
  enabled     = var.create_core
  owner_tag   = var.owner_tag
}

output "planned_tags" {
  value = module.guardrails.tags
}
