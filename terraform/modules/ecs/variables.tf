variable "project_name" {
  description = "Prefix applied to ECS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ECS and CloudWatch logs"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS/ALB resources. If empty, default VPC is used."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets for ALB and ECS service. If empty, all subnets in selected VPC are used."
  type        = list(string)
  default     = []
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

variable "health_check_path" {
  description = "ALB target group health check path for the frontend service"
  type        = string
  default     = "/"
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
