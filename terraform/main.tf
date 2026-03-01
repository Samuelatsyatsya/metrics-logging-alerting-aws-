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

module "network" {
  count  = var.enable_ecs ? 1 : 0
  source = "./modules/network"

  project_name                   = var.project_name
  vpc_cidr_block                 = var.network_vpc_cidr_block
  public_subnet_cidr_blocks      = var.network_public_subnet_cidr_blocks
  public_subnet_azs              = var.network_public_subnet_azs
  map_public_ip_on_launch        = var.network_map_public_ip_on_launch
  enable_dns_support             = var.network_enable_dns_support
  enable_dns_hostnames           = var.network_enable_dns_hostnames
  frontend_container_port        = var.ecs_frontend_container_port
  health_check_path              = var.ecs_health_check_path
  alb_internal                   = var.ecs_alb_internal
  alb_drop_invalid_header_fields = var.ecs_alb_drop_invalid_header_fields
  alb_ingress_cidr_blocks        = var.ecs_alb_ingress_cidr_blocks
  alb_egress_cidr_blocks         = var.ecs_alb_egress_cidr_blocks
  ecs_service_egress_cidr_blocks = var.ecs_service_egress_cidr_blocks
  alb_listener_port              = var.ecs_alb_listener_port
  alb_certificate_arn            = var.ecs_alb_certificate_arn
  alb_ssl_policy                 = var.ecs_alb_ssl_policy
  tags                           = var.tags
}

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./modules/ecs"

  project_name              = var.project_name
  aws_region                = var.aws_region
  subnet_ids                = module.network[0].subnet_ids
  service_security_group_id = module.network[0].ecs_service_security_group_id
  frontend_target_group_arn = module.network[0].frontend_target_group_arn
  assign_public_ip          = var.ecs_assign_public_ip
  desired_count             = var.ecs_desired_count
  task_cpu                  = var.ecs_task_cpu
  task_memory               = var.ecs_task_memory
  backend_container_name    = var.ecs_backend_container_name
  frontend_container_name   = var.ecs_frontend_container_name
  backend_container_port    = var.ecs_backend_container_port
  frontend_container_port   = var.ecs_frontend_container_port
  backend_env               = var.ecs_backend_env
  frontend_env              = var.ecs_frontend_env
  backend_image             = var.backend_image
  frontend_image            = var.frontend_image
  tags                      = var.tags

  depends_on = [module.network]
}

moved {
  from = module.ecs[0].aws_security_group.alb
  to   = module.network[0].aws_security_group.alb
}

moved {
  from = module.ecs[0].aws_security_group.ecs_service
  to   = module.network[0].aws_security_group.ecs_service
}

moved {
  from = module.ecs[0].aws_lb.main
  to   = module.network[0].aws_lb.main
}

moved {
  from = module.ecs[0].aws_lb_target_group.frontend
  to   = module.network[0].aws_lb_target_group.frontend
}

moved {
  from = module.ecs[0].aws_lb_listener.https[0]
  to   = module.network[0].aws_lb_listener.https
}
