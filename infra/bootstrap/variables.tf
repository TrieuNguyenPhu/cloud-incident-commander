variable "provision_bootstrap" {
  type    = bool
  default = false
  validation {
    condition     = !var.provision_bootstrap || can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Bootstrap requires the reviewed 12-digit AWS account ID."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "ADR-018 restricts P0 to us-east-1 until a reviewed region change."
  }
}

variable "aws_account_id" {
  type    = string
  default = null
}

variable "state_bucket_name" {
  type    = string
  default = null
}

variable "owner_tag" {
  type    = string
  default = "UNCONFIGURED"
}

variable "budget_email" {
  type    = string
  default = null
}

variable "core_budget_alert_usd" {
  type    = number
  default = 25
}

variable "backend_role_arns" {
  type    = list(string)
  default = []
}
