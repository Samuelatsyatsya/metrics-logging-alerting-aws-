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
