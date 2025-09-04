
variable "log_group_name" {
  description = "The name of the CloudWatch log group."
  type        = string
}

variable "metric_filter_name" {
  description = "The name of the metric filter."
  type        = string
}

variable "metric_filter_pattern" {
  description = "The pattern to filter logs."
  type        = string
}

variable "metric_name" {
  description = "The name of the metric to create."
  type        = string
}

variable "metric_namespace" {
  description = "The namespace for the metric."
  type        = string
}

variable "sns_topic_name" {
  description = "The name of the SNS topic."
  type        = string
}

variable "email_addresses" {
  description = "A list of email addresses to subscribe to the SNS topic."
  type        = list(string)
}

variable "alarm_name" {
  description = "The name of the CloudWatch alarm."
  type        = string
}

variable "alarm_threshold" {
  description = "The threshold for the CloudWatch alarm."
  type        = number
}
