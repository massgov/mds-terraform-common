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

variable "filter_container_names" {
  type        = list(string)
  description = "List of ECS container names to monitor."
  default     = []
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 60
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 300
}

variable "memory_threshold" {
  type        = number
  description = "Maximum memory percentage allowed before triggering alert."
  default     = 90
}

variable "restart_count_threshold" {
  type        = number
  description = "Maximum number of unique task arns before triggering alert."
  default     = 5
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
