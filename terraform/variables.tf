variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID, used in S3 bucket naming and CloudTrail ARN conditions"
  type        = string
}

variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log group entries for CloudTrail"
  type        = number
  default     = 90
}

variable "glacier_transition_days" {
  description = "Days after which CloudTrail S3 objects transition to Glacier"
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Days after which CloudTrail S3 objects are permanently deleted"
  type        = number
  default     = 365
}

variable "finding_publishing_frequency" {
  description = "How often GuardDuty publishes findings: FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_ecs" {
  description = "Whether to provision ECS infrastructure"
  type        = bool
}

variable "vpc_id" {
  description = "VPC ID for ECS resources. If empty, default VPC is used."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS/ALB resources. If empty, all subnets in VPC are used."
  type        = list(string)
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

variable "ecs_health_check_path" {
  description = "HTTP path used by ALB target group health checks"
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
