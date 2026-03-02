variable "project_name" {
  description = "Project prefix used for CodeDeploy resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used for the green target group"
  type        = string
}

variable "frontend_container_port" {
  description = "Frontend container port used by the target groups"
  type        = number
}

variable "health_check_path" {
  description = "Health check path for the green target group"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name referenced by CodeDeploy deployment group"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name referenced by CodeDeploy deployment group"
  type        = string
}

variable "prod_listener_arn" {
  description = "Production listener ARN used by the ECS service ALB"
  type        = string
}

variable "prod_target_group_name" {
  description = "Existing production target group name attached to ECS service"
  type        = string
}

variable "create_deployment_group" {
  description = "Whether to create the CodeDeploy deployment group resources"
  type        = bool
}

variable "tags" {
  description = "Tags applied to CodeDeploy resources"
  type        = map(string)
}
