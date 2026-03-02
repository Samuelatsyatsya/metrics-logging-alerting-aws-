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

locals {
  backend_env_for_ecs = var.enable_ecs && var.enable_rds ? merge(var.ecs_backend_env, {
    DB_HOST    = module.rds[0].endpoint
    DB_PORT    = tostring(var.rds_db_port)
    DB_NAME    = var.rds_db_name
    DB_USER    = var.rds_db_username
    DB_DIALECT = "mysql"
  }) : var.ecs_backend_env

  backend_secrets_for_ecs = var.enable_ecs && var.enable_rds ? {
    DB_PASSWORD = "${module.rds[0].credentials_secret_arn}:password::"
  } : {}

  backend_secret_arns_for_ecs = var.enable_ecs && var.enable_rds ? [
    module.rds[0].credentials_secret_arn
  ] : []
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

module "rds" {
  count  = var.enable_ecs && var.enable_rds ? 1 : 0
  source = "./modules/rds"

  project_name                  = var.project_name
  subnet_ids                    = module.network[0].subnet_ids
  vpc_id                        = module.network[0].vpc_id
  ecs_service_security_group_id = module.network[0].ecs_service_security_group_id
  db_identifier                 = var.rds_db_identifier
  db_name                       = var.rds_db_name
  db_username                   = var.rds_db_username
  db_password                   = var.rds_db_password
  db_port                       = var.rds_db_port
  engine_version                = var.rds_engine_version
  instance_class                = var.rds_instance_class
  allocated_storage             = var.rds_allocated_storage
  max_allocated_storage         = var.rds_max_allocated_storage
  storage_type                  = var.rds_storage_type
  multi_az                      = var.rds_multi_az
  publicly_accessible           = var.rds_publicly_accessible
  backup_retention_period       = var.rds_backup_retention_period
  deletion_protection           = var.rds_deletion_protection
  skip_final_snapshot           = var.rds_skip_final_snapshot
  credentials_secret_name       = var.rds_credentials_secret_name
  tags                          = var.tags

  depends_on = [module.network]
}

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./modules/ecs"

  project_name               = var.project_name
  aws_region                 = var.aws_region
  subnet_ids                 = module.network[0].subnet_ids
  service_security_group_id  = module.network[0].ecs_service_security_group_id
  frontend_target_group_arn  = module.network[0].frontend_target_group_arn
  deployment_controller_type = var.ecs_deployment_controller_type
  assign_public_ip           = var.ecs_assign_public_ip
  desired_count              = var.ecs_desired_count
  task_cpu                   = var.ecs_task_cpu
  task_memory                = var.ecs_task_memory
  backend_container_name     = var.ecs_backend_container_name
  frontend_container_name    = var.ecs_frontend_container_name
  backend_container_port     = var.ecs_backend_container_port
  frontend_container_port    = var.ecs_frontend_container_port
  backend_env                = local.backend_env_for_ecs
  backend_secrets            = local.backend_secrets_for_ecs
  backend_secret_arns        = local.backend_secret_arns_for_ecs
  frontend_env               = var.ecs_frontend_env
  backend_image              = var.backend_image
  frontend_image             = var.frontend_image
  tags                       = var.tags

  depends_on = [module.network, module.rds]
}

module "jenkins_iam" {
  count  = var.enable_ecs && var.enable_jenkins_iam_policy ? 1 : 0
  source = "./modules/jenkins_iam"

  project_name     = var.project_name
  aws_region       = var.aws_region
  ecs_cluster_name = module.ecs[0].cluster_name
  ecs_service_name = module.ecs[0].service_name
  pass_role_arns = [
    module.ecs[0].task_execution_role_arn,
    module.ecs[0].task_role_arn
  ]
  principal_type = var.jenkins_iam_principal_type
  principal_name = var.jenkins_iam_principal_name
  tags           = var.tags

  depends_on = [module.ecs]
}

module "codedeploy" {
  count  = var.enable_ecs && var.enable_codedeploy ? 1 : 0
  source = "./modules/codedeploy"

  project_name            = var.project_name
  vpc_id                  = module.network[0].vpc_id
  frontend_container_port = var.ecs_frontend_container_port
  health_check_path       = var.ecs_health_check_path
  ecs_cluster_name        = module.ecs[0].cluster_name
  ecs_service_name        = module.ecs[0].service_name
  prod_listener_arn       = module.network[0].alb_listener_arn
  prod_target_group_name  = module.network[0].frontend_target_group_name
  create_deployment_group = var.codedeploy_create_deployment_group
  tags                    = var.tags

  depends_on = [module.network, module.ecs]
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
