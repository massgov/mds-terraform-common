# ---------------------------------------------------------------------------
# Required
# ---------------------------------------------------------------------------

variable "name_prefix" {
  type        = string
  description = "Short prefix used to name every resource created by this module (e.g. \"myapp\")."
}

# ---------------------------------------------------------------------------
# SNS — create a new topic or bring your own
# ---------------------------------------------------------------------------

variable "sns_topic_arn" {
  type        = string
  default     = null
  description = <<-EOT
    ARN of an existing SNS topic to publish notifications to.
    When set, the module will NOT create a new SNS topic and
    sns_email_subscriptions is ignored.
    When null (default), a new SNS topic is created by this module.
  EOT

  validation {
    condition     = var.sns_topic_arn == null || can(regex("^arn:[a-z0-9-]+:sns:", var.sns_topic_arn))
    error_message = "sns_topic_arn must be a valid SNS topic ARN (arn:<partition>:sns:...)."
  }
}

variable "sns_email_subscriptions" {
  type        = list(string)
  default     = []
  description = "List of e-mail addresses to subscribe to the SNS topic created by this module. Ignored when sns_topic_arn is provided."
}

# ---------------------------------------------------------------------------
# IAM user filter
# ---------------------------------------------------------------------------

variable "name_pattern" {
  type        = string
  default     = "*"
  description = "Glob pattern matched against IAM usernames (e.g. \"*Example*\"). Defaults to all users."
}

variable "tag_key" {
  type        = string
  default     = ""
  description = "Optional IAM tag key. When set, only users that carry this tag (with tag_value) are checked."
}

variable "tag_value" {
  type        = string
  default     = ""
  description = "Optional IAM tag value paired with tag_key."
}

# ---------------------------------------------------------------------------
# Notification thresholds
# ---------------------------------------------------------------------------

variable "warning_days" {
  type        = number
  default     = 80
  description = "Publish a WARNING notification when a key is this many days old."

  validation {
    condition     = var.warning_days > 0
    error_message = "warning_days must be a positive integer."
  }
}

variable "alert_days" {
  type        = number
  default     = 90
  description = "Publish an ALERT notification when a key is this many days old. Must be >= warning_days."

  validation {
    condition     = var.alert_days > 0
    error_message = "alert_days must be a positive integer."
  }

}

# ---------------------------------------------------------------------------
# Schedule
# ---------------------------------------------------------------------------

variable "schedule_expression" {
  type        = string
  default     = "rate(1 day)"
  description = "EventBridge schedule expression. Defaults to once per day."
}

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags applied to every resource."
}

# ---------------------------------------------------------------------------
# auto_disable
# ---------------------------------------------------------------------------

variable "auto_disable" {
  type        = bool
  default     = false
  description = "Whether to automatically disable keys that have reached the alert threshold. Defaults to false."
}