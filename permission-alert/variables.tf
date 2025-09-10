variable "role_names" {
  description = "List of IAM role names to monitor for admin-like privileges"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN to publish alerts to."
  type        = string
}
