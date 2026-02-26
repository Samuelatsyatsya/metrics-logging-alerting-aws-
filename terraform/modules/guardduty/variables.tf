variable "finding_publishing_frequency" {
  description = "How often GuardDuty exports findings: FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS"
  type        = string

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
