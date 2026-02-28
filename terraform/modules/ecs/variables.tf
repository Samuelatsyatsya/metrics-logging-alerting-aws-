variable "project_name" {
  description = "Prefix applied to ECS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ECS and CloudWatch logs"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ECS service networking"
  type        = list(string)
}

variable "service_security_group_id" {
  description = "Security group ID assigned to ECS service tasks"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ALB target group ARN for frontend container"
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to ECS tasks"
  type        = bool
  default     = true
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Task CPU units (e.g., 256, 512, 1024)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task memory in MiB (e.g., 512, 1024, 2048)"
  type        = number
  default     = 1024
}

variable "backend_image" {
  description = "Backend container image URI"
  type        = string
}

variable "frontend_image" {
  description = "Frontend container image URI"
  type        = string
}

variable "backend_container_name" {
  description = "Backend ECS container name"
  type        = string
  default     = "backend"
}

variable "frontend_container_name" {
  description = "Frontend ECS container name"
  type        = string
  default     = "frontend"
}

variable "backend_container_port" {
  description = "Backend container port"
  type        = number
  default     = 5000
}

variable "frontend_container_port" {
  description = "Frontend container port"
  type        = number
  default     = 80
}

variable "backend_env" {
  description = "Environment variables for backend container"
  type        = map(string)
  default     = {}
}

variable "frontend_env" {
  description = "Environment variables for frontend container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
