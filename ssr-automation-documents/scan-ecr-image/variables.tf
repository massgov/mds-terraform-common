variable "region" {
  type        = "string"
  description = "Region where automation should be performed. Defaults to provider-configured region"
  default     = null
}

variable "account_id" {
  type        = "string"
  description = "AWS account where automation should be performed"
  default     = null
}

variable "default_alerting_topic" {
  type        = "string"
  description = "Default SNS topic to use for alerting"
}
