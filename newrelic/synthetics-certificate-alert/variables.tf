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

variable "domain" {
  type        = string
  description = "The domain to monitor."
}

variable "period" {
  type        = string
  description = "See newrelic_synthetics_monitor.period."
  # Every hour is excessive, but it makes the alert much easier to create.
  default     = "EVERY_HOUR"
}

variable "certificate_expiration" {
  type        = number
  description = "See newrelic_synthetics_cert_check_monitor.certification_expiration."
  default     = 30
}

variable "locations" {
  type        = list(string)
  description = "See newrelic_synthetics_monitor.locations_public."
  default     = ["US_EAST_1", "US_EAST_2"]
}

variable "critical_threshold" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold."
  default     = 1
}

variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 3600
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 3600
}

variable "aggregation_delay" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_delay."
  default     = 300
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
