variable "account_id" {
  type        = number
  description = "See newrelic_nrql_alert_condition.account_id"
}

variable "policy_id" {
  type        = number
  description = "See newrelic_nrql_alert_condition.policy_id."
}

variable "type" {
  type        = string
  description = "See newrelic_nrql_alert_condition.type."
  default     = "static"
}

variable "name" {
  type        = string
  description = "See newrelic_nrql_alert_condition.name."
}

variable "enabled" {
  type        = bool
  description = "See newrelic_nrql_alert_condition.enabled."
  default     = true
}

variable "violation_time_limit_seconds" {
  type        = number
  description = "See newrelic_nrql_alert_condition.violation_time_limit_seconds."
  default     = 259200
}

variable "nrql_query" {
  type        = string
  description = "See newrelic_nrql_alert_condition.nrql.query."
}

variable "critical_operator" {
  type        = string
  description = "See newrelic_nrql_alert_condition.critical.operator."
  default     = "above"
}

variable "critical_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
}

variable "critical_threshold_occurrences" {
  type        = string
  default     = "all"
  description = "See newrelic_nrql_alert_condition.critical.threshold_occurrences."
}

variable "fill_option" {
  type        = string
  description = "See newrelic_nrql_alert_condition.fill_option."
  default     = "none"
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
}

variable "aggregation_method" {
  type        = string
  description = "See newrelic_nrql_alert_condition.aggregation_method."
}

variable "aggregation_delay" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_delay."
  default     = null
}

variable "aggregation_timer" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_timer."
  default     = null
}

variable "expiration_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.expiration_duration."
  default     = null
}

variable "open_violation_on_expiration" {
  type        = bool
  description = "See newrelic_nrql_alert_condition.open_violation_on_expiration."
  default     = false
}

variable "close_violations_on_expiration" {
  type        = bool
  description = "See newrelic_nrql_alert_condition.close_violations_on_expiration."
  default     = false
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}

