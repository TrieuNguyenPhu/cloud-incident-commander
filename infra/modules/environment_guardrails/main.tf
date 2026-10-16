variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "lab"], var.environment)
    error_message = "Only reviewed dev/lab environments are supported."
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

variable "enabled" {
  type    = bool
  default = false
}

variable "is_lab" {
  type = bool
}

variable "owner_tag" {
  type    = string
  default = "UNCONFIGURED"
  validation {
    condition     = !var.enabled || (trimspace(var.owner_tag) != "" && var.owner_tag != "UNCONFIGURED")
    error_message = "An enabled environment must have a named owner."
  }
}

variable "lab_max_runtime_hours" {
  type    = number
  default = 4
  validation {
    condition     = var.lab_max_runtime_hours > 0 && var.lab_max_runtime_hours <= 4
    error_message = "P0 allows a maximum four-hour lab window; longer runs need a reviewed cost decision."
  }
}

variable "lab_expires_at" {
  type    = string
  default = null
  validation {
    condition = !var.enabled || !var.is_lab || try(
      timecmp(var.lab_expires_at, plantimestamp()) > 0 &&
      timecmp(var.lab_expires_at, timeadd(plantimestamp(), "${var.lab_max_runtime_hours}h")) <= 0,
      false
    )
    error_message = "Enabled labs need a valid RFC3339 expiry in the next approved runtime window."
  }
}

output "tags" {
  value = {
    project     = "cic"
    environment = var.environment
    owner       = var.owner_tag
    managed_by  = "terraform"
    expires_at  = var.is_lab ? var.lab_expires_at : "persistent"
  }
}
