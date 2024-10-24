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

variable "filter_exclude_mount_points" {
  type        = list(string)
  description = "List of volume mount points to exclude."
  default     = []
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = null
}

variable "cpu_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 90
}

variable "memory_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 90
}

variable "storage_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 90
}

variable "loss_of_signal_time" {
  type        = number
  description = "See newrelic_nrql_alert_condition.expiration_duration."
  default     = 600
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = null
}

variable "alert_loss_of_signal" {
  type        = bool
  description = "Create an alert when metrics from an instance name stop."
  default     = false
}

variable "use_agent_metrics" {
  type        = bool
  description = "Build the alerts using the extended metrics generated by the New Relic EC2 agent."
  default     = false
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
