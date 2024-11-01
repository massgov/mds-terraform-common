variable "topic_name" {
  type        = string
  description = "The name of the SNS topic to which the alerts should be sent."
}

variable "role_arns" {
  type        = list(string)
  description = "The ARNs of the roles that should trigger an alert when assumed."
}
