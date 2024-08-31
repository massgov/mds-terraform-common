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

variable "filter_function_names" {
  type        = list(string)
  description = "List of Lambda Function names to monitor."
  default     = []
}

variable "exclude_function_names" {
  type        = list(string)
  description = "List of Lambda Function names to NOT monitor (all others will be monitored)."
  default     = []
}

variable "aggregation_window" {
  type        = number
  description = "See newrelic_nrql_alert_condition.aggregation_window."
  default     = 3600
}

# This should be, at minimum, the frequency at which the lambda runs. If this
# only runs once per hour, then it should be at least 3600.
variable "critical_threshold_duration" {
  type        = number
  description = "See newrelic_nrql_alert_condition.critical.threshold_duration."
  default     = 3600
}

variable "error_percent_threshold" {
  description = "Maximum Error percentage (0 - 100%) allowed before triggering alert."
  default     = 5

  validation {
    condition     = tonumber(var.error_percent_threshold) == var.error_percent_threshold || var.error_percent_threshold == null
    error_message = "The error_percent_threshold value should either be a number or null (which would disable the error_percent alert)."
  }

  validation {
    condition     = var.error_percent_threshold == null || (var.error_percent_threshold >= 0 && var.error_percent_threshold <= 100)
    error_message = "The error_percent_threshold value should be between 0 and 100 (or null)."
  }
}

variable "events_dropped_threshold" {
  description = "Maximum number of dropped events allowed before triggering alert."
  default     = 1

  validation {
    condition     = tonumber(var.events_dropped_threshold) == var.events_dropped_threshold || var.events_dropped_threshold == null
    error_message = "The events_dropped_threshold value should either be a number or null (which would disable the events_dropped alert)."
  }
}

variable "duration_threshold" {
  description = "Duration (in milliseconds) allowed before triggering alert."
  default     = 300000

  validation {
    condition     = tonumber(var.duration_threshold) == var.duration_threshold || var.duration_threshold == null
    error_message = "The duration_threshold value should either be a number or null (which would disable the duration alert)."
  }
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings."
  default     = {}
}
