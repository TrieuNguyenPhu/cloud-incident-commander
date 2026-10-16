variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "enable_rosa_lab" {
  type    = bool
  default = false
  validation {
    condition     = !var.enable_rosa_lab
    error_message = "P7 resources are not implemented in P0. Keep this flag false until that phase is reviewed."
  }
}

variable "owner_tag" {
  type    = string
  default = "UNCONFIGURED"
}

variable "lab_expires_at" {
  type    = string
  default = null
}

variable "lab_max_runtime_hours" {
  type    = number
  default = 4
}

module "guardrails" {
  aws_region            = var.aws_region
  source                = "../../../modules/environment_guardrails"
  environment           = "lab"
  is_lab                = true
  enabled               = var.enable_rosa_lab
  owner_tag             = var.owner_tag
  lab_expires_at        = var.lab_expires_at
  lab_max_runtime_hours = var.lab_max_runtime_hours
}

output "planned_tags" {
  value = module.guardrails.tags
}
