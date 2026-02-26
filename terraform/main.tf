terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "cloudtrail" {
  source = "./modules/cloudtrail"

  project_name            = var.project_name
  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  log_retention_days      = var.log_retention_days
  glacier_transition_days = var.glacier_transition_days
  log_expiration_days     = var.log_expiration_days
  tags                    = var.tags
}

module "guardduty" {
  source = "./modules/guardduty"

  finding_publishing_frequency = var.finding_publishing_frequency
  tags                         = var.tags
}
