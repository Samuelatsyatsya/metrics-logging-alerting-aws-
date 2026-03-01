variable "project_name" {
  description = "Project prefix used in policy naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region where ECS resources run"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name Jenkins will operate on"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name Jenkins will operate on"
  type        = string
}

variable "pass_role_arns" {
  description = "IAM role ARNs Jenkins is allowed to pass to ECS tasks"
  type        = list(string)
}

variable "principal_type" {
  description = "IAM principal type to attach policy to: user or role"
  type        = string

  validation {
    condition     = contains(["user", "role"], var.principal_type)
    error_message = "principal_type must be either 'user' or 'role'."
  }
}

variable "principal_name" {
  description = "IAM user or role name that Jenkins uses"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM policy"
  type        = map(string)
}
