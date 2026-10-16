variable "bucket_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Supply a reviewed, globally unique S3 state bucket name."
  }
}

variable "owner_tag" {
  type = string
  validation {
    condition     = try(trimspace(var.owner_tag) != "" && var.owner_tag != "UNCONFIGURED", false)
    error_message = "A named cleanup/state owner is mandatory."
  }
}

variable "budget_email" {
  type = string
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.budget_email))
    error_message = "Supply the recipient for the reviewed budget alerts."
  }
}

variable "budget_limit_usd" {
  type = number
  validation {
    condition     = var.budget_limit_usd > 0
    error_message = "Budget alert threshold must be positive."
  }
}

variable "backend_role_arns" {
  type = list(string)
  validation {
    condition = length(var.backend_role_arns) > 0 && alltrue([
      for arn in var.backend_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/[A-Za-z0-9_+=,.@/-]+$", arn))
    ])
    error_message = "Explicit IAM role ARNs are required for backend access; wildcards are forbidden."
  }
}
