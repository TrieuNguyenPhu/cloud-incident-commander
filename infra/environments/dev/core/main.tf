variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "create_core" {
  type    = bool
  default = false
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

module "web" {
  count       = var.create_core ? 1 : 0
  source      = "../../../modules/cloudfront_static"
  environment = "dev"
  tags        = module.guardrails.tags
}

output "web_bucket_name" {
  value = try(module.web[0].bucket_name, null)
}

output "web_distribution_domain_name" {
  value = try(module.web[0].distribution_domain_name, null)
}
