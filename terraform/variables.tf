variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}

variable "enable_ecs" {
  description = "Whether to provision ECS infrastructure"
  type        = bool
}

variable "enable_jenkins_iam_policy" {
  description = "Whether to create and attach Jenkins ECS deployment IAM policy"
  type        = bool
}

variable "enable_codedeploy" {
  description = "Whether to provision CodeDeploy resources for future ECS blue/green deployments"
  type        = bool
  default     = false
}

variable "codedeploy_create_deployment_group" {
  description = "Whether to create the CodeDeploy deployment group. Keep false while ECS uses rolling deployments."
  type        = bool
  default     = false

  validation {
    condition     = !var.codedeploy_create_deployment_group || var.ecs_deployment_controller_type == "CODE_DEPLOY"
    error_message = "codedeploy_create_deployment_group can only be true when ecs_deployment_controller_type is CODE_DEPLOY."
  }
}

variable "ecs_deployment_controller_type" {
  description = "ECS service deployment controller type: ECS for rolling updates or CODE_DEPLOY for blue/green."
  type        = string
  default     = "ECS"

  validation {
    condition     = contains(["ECS", "CODE_DEPLOY"], var.ecs_deployment_controller_type)
    error_message = "ecs_deployment_controller_type must be either ECS or CODE_DEPLOY."
  }
}

variable "jenkins_iam_principal_type" {
  description = "IAM principal type Jenkins uses (user or role)"
  type        = string

  validation {
    condition     = contains(["user", "role"], var.jenkins_iam_principal_type)
    error_message = "jenkins_iam_principal_type must be either 'user' or 'role'."
  }
}

variable "jenkins_iam_principal_name" {
  description = "IAM user/role name Jenkins uses"
  type        = string
}

variable "network_vpc_cidr_block" {
  description = "CIDR block for the VPC created by the network module"
  type        = string
}

variable "network_public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets created by the network module"
  type        = list(string)
}

variable "network_public_subnet_azs" {
  description = "Availability zones for public subnets (same order as network_public_subnet_cidr_blocks)"
  type        = list(string)
}

variable "network_map_public_ip_on_launch" {
  description = "Whether public subnets auto-assign public IPs"
  type        = bool
}

variable "network_enable_dns_support" {
  description = "Whether VPC DNS support is enabled"
  type        = bool
}

variable "network_enable_dns_hostnames" {
  description = "Whether VPC DNS hostnames are enabled"
  type        = bool
}

variable "ecs_assign_public_ip" {
  description = "Whether ECS tasks should receive public IPs"
  type        = bool
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task definition"
  type        = number
}

variable "ecs_task_memory" {
  description = "Memory (MiB) for ECS task definition"
  type        = number
}

variable "ecs_backend_container_name" {
  description = "Backend container name in ECS task definition"
  type        = string
}

variable "ecs_frontend_container_name" {
  description = "Frontend container name in ECS task definition"
  type        = string
}

variable "ecs_backend_container_port" {
  description = "Backend container port in ECS task definition"
  type        = number
}

variable "ecs_frontend_container_port" {
  description = "Frontend container port in ECS task definition"
  type        = number
}

variable "enable_rds" {
  description = "Whether to provision RDS infrastructure for backend database"
  type        = bool
}

variable "rds_db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_db_name" {
  description = "RDS initial database name"
  type        = string
}

variable "rds_db_username" {
  description = "RDS master username"
  type        = string
}

variable "rds_db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_db_port" {
  description = "RDS port"
  type        = number
}

variable "rds_engine_version" {
  description = "RDS MySQL engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "RDS max autoscaled storage in GB"
  type        = number
}

variable "rds_storage_type" {
  description = "RDS storage type"
  type        = string
}

variable "rds_multi_az" {
  description = "Whether RDS should be deployed in Multi-AZ mode"
  type        = bool
}

variable "rds_publicly_accessible" {
  description = "Whether RDS should be publicly accessible"
  type        = bool
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
}

variable "rds_deletion_protection" {
  description = "Whether to enable RDS deletion protection"
  type        = bool
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip RDS final snapshot on destroy"
  type        = bool
}

variable "rds_credentials_secret_name" {
  description = "Secrets Manager secret name storing DB credentials"
  type        = string
}

variable "ecs_health_check_path" {
  description = "HTTP path used by ALB target group health checks"
  type        = string
}

variable "ecs_alb_internal" {
  description = "Whether ECS ALB is internal/private"
  type        = bool
}

variable "ecs_alb_drop_invalid_header_fields" {
  description = "Whether ALB should drop invalid HTTP header fields"
  type        = bool
}

variable "ecs_alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach ALB listener"
  type        = list(string)
}

variable "ecs_alb_egress_cidr_blocks" {
  description = "CIDR blocks allowed for ALB egress; empty list uses VPC CIDR"
  type        = list(string)
}

variable "ecs_service_egress_cidr_blocks" {
  description = "CIDR blocks allowed for ECS task egress"
  type        = list(string)

  validation {
    condition     = length(var.ecs_service_egress_cidr_blocks) > 0
    error_message = "ecs_service_egress_cidr_blocks must contain at least one CIDR (for example [\"0.0.0.0/0\"])."
  }
}

variable "ecs_alb_listener_port" {
  description = "ALB listener port"
  type        = number
}

variable "ecs_alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS ALB listener"
  type        = string
}

variable "ecs_alb_ssl_policy" {
  description = "SSL policy for HTTPS ALB listener"
  type        = string
}

variable "backend_image" {
  description = "Backend container image URI override"
  type        = string
}

variable "frontend_image" {
  description = "Frontend container image URI override"
  type        = string
}

variable "ecs_backend_env" {
  description = "Environment variables for backend container in ECS task definition"
  type        = map(string)
}

variable "ecs_frontend_env" {
  description = "Environment variables for frontend container in ECS task definition"
  type        = map(string)
}
