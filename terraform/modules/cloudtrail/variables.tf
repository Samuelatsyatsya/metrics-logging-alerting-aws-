variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
}

variable "glacier_transition_days" {
  description = "Days before S3 objects transition to Glacier"
  type        = number
}

variable "log_expiration_days" {
  description = "Days before S3 objects are deleted"
  type        = number
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
