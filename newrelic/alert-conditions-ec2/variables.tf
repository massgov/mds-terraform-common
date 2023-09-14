variable "name_prefix" {
  type        = string
  description = "Name prefix for the alert condition"
}

variable "account_id" {
  type        = string
  description = "The account number for the New Relic account."
}

variable "alert_policy_id" {
  type        = string
  description = "The id of the New Relic alert policy."
}

variable "filter_aws_accounts" {
  type        = list(string)
  description = "List of AWS account ids to monitor."
  default     = []
}

variable "filter_instance_names" {
  type        = list(string)
  description = "List of EC2 instance names to monitor."
  default     = []
}

variable "filter_asg_names" {
  type        = list(string)
  description = "List of asg names to monitor."
  default     = []
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 300
}

variable "critical_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 90
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 300
}

variable "open_violation_on_expiration" {
  type        = bool
  description = "See newrelic_nrql_alert_condition.open_violation_on_expiration."
  default     = false
}
