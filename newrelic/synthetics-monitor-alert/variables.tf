variable "account_id" {
  type        = number
  description = "See newrelic_nrql_alert_condition.account_id"
}

variable "policy_id" {
  type        = number
  description = "See newrelic_nrql_alert_condition.policy_id. When null, a new policy will be created."
  default     = null
}

variable "name" {
  type        = string
  description = "Name will be used as a prefix for the monitor, alert, and policy."
}

variable "uri" {
  type        = string
  description = "The URI to monitor."
}

variable "period" {
  type        = string
  description = "See newrelic_synthetics_monitor.period."
  default     = "EVERY_MINUTE"
}

variable "locations" {
  type        = list(string)
  description = "See newrelic_synthetics_monitor.locations_public."
  default     = ["US_EAST_1", "US_EAST_2", "US_WEST_1", "US_WEST_2"]
}

variable "treat_redirect_as_failure" {
  type        = bool
  description = "See newrelic_synthetics_monitor.treat_redirect_as_failure."
  default     = true
}

variable "validation_string" {
  type        = string
  description = "See newrelic_synthetics_monitor.validation_string."
  default     = ""
}

variable "headers" {
  type        = map(string)
  description = "Custom headers to use for the monitor request."
  default     = {}
}

variable "critical_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 1
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 300
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 60
}

variable "aggregation_delay" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_delay."
  default     = 120
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
