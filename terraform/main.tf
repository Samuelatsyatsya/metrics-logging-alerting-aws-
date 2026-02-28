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

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./modules/ecs"

  project_name            = var.project_name
  aws_region              = var.aws_region
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  assign_public_ip        = var.ecs_assign_public_ip
  desired_count           = var.ecs_desired_count
  task_cpu                = var.ecs_task_cpu
  task_memory             = var.ecs_task_memory
  backend_container_name  = var.ecs_backend_container_name
  frontend_container_name = var.ecs_frontend_container_name
  backend_container_port  = var.ecs_backend_container_port
  frontend_container_port = var.ecs_frontend_container_port
  health_check_path       = var.ecs_health_check_path
  backend_env             = var.ecs_backend_env
  frontend_env            = var.ecs_frontend_env
  backend_image           = var.backend_image
  frontend_image          = var.frontend_image
  tags                    = var.tags
}
