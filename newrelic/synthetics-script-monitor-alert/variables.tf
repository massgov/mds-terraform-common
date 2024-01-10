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

variable "period" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.period."
  default     = "EVERY_10_MINUTES"
}

variable "locations" {
  type        = list(string)
  description = "See newrelic_synthetics_script_monitor.locations_public."
  default     = ["US_EAST_1", "US_EAST_2", "US_WEST_1", "US_WEST_2"]
}

variable "type" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.type."
  default     = "SCRIPT_API"
}

variable "script" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.script."
}

variable "script_language" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.script_language."
  default     = null
}

variable "runtime_type" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.runtime_type."
  default     = null
}

variable "runtime_type_version" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.runtime_type_version."
  default     = null
}

variable "enable_screenshot_on_failure_and_script" {
  type        = bool
  description = "See newrelic_synthetics_script_monitor.enable_screenshot_on_failure_and_script."
  default     = false
}

variable "device_orientation" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.device_orientation."
  default     = null
}

variable "device_type" {
  type        = string
  description = "See newrelic_synthetics_script_monitor.device_type."
  default     = null
}

variable "critical_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 1
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 1800
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 600
}

variable "aggregation_delay" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_delay."
  default     = 1200
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
