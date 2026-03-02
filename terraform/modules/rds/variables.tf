variable "project_name" {
  description = "Prefix applied to RDS resources"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where RDS runs"
  type        = string
}

variable "ecs_service_security_group_id" {
  description = "Security group ID used by ECS service tasks"
  type        = string
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
}

variable "engine_version" {
  description = "MySQL engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GB"
  type        = number
}

variable "storage_type" {
  description = "RDS storage type"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
}

variable "publicly_accessible" {
  description = "Whether RDS is publicly accessible"
  type        = bool
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on destroy"
  type        = bool
}

variable "credentials_secret_name" {
  description = "Secrets Manager secret name for DB credentials"
  type        = string
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
}
