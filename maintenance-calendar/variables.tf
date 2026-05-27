variable "maintenance_sns_topic" {
  type        = string
  description = "Name of the SNS topic to use for maintenance notifications"
}

variable "maintenance_sns_display_name" {
  type        = string
  description = "(Optional) Display name for the maintenance notifications SNS topic"
  default     = null
}

variable "maintenance_logs_bucket" {
  type        = string
  description = "Name of the S3 bucket to store maintenance logs"
}

variable "create_ecs_scans" {
  type        = bool
  description = "Determines if maintenance calendar tasks for ECS/ECR scanning will be created"
  default     = false
}

variable "scan_ecs_clusters" {
  type = map(
    list(string)
  )
  description = "Map relating project titles to a list of ECS cluster names which ought to be scanned periodically"
  default     = {}
}

variable "scan_ecr_repositories" {
  type = map(
    list(string)
  )
  description = "Map relating project titles to a list of ECR repository names which ought to be scanned periodically"
  default     = {}
}

variable "image_scan_ignore_arn" {
  type        = string
  default     = null
  description = <<EOF
    ARN of an SSM parameter containing CVEs that can safely be ignored.
    This parameter must be created manually if it doesn't already exist.

    Parameter format: `[{"name":"CVE-2024-1", "packageName":"cowsay", "packageVersion":["1.2.3", "1.2.4"]},{"name"...}]`
  EOF
}

variable "image_scan_snooze_arn" {
  type        = string
  default     = null
  description = <<EOF
    ARN of an SSM parameter containing ECS cluster names and a date to snooze alerts.
    This parameter must be created manually if it doesn't already exist.

    Parameter format: `[{"cluster":"ecs-cluster-1", "snoozeUntil":"2024-10-24"},{"cluster"...}]`
  EOF
}

variable "create_rds_snapshots" {
  type        = bool
  description = "Determines if maintenance calendar tasks for managaing RDS snapshots will be created"
  default     = false
}

variable "rds_instance_names" {
  type        = list(string)
  description = "A list of RDS instance names we want to manage snapshots for"
  default     = null
}

variable "create_github_inactive_user_reminder" {
  type        = bool
  description = "Determines if the inactive github user reminder will be created"
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "s3_lifecycle_filter" {
  type        = string
  description = "A single filter prefix or tag to apply to the only S3 lifecycle rule"
  default     = null
}


# ---------------------------------------------------------------------------
# User Access Key Age Check
# ---------------------------------------------------------------------------

variable "create_user_access_key_age_check" {
  type        = bool
  description = "Determines if the user access key age check will be created"
  default     = false
}

variable "user_access_name_prefix" {
  type        = string
  description = "Short prefix used to name every resource created by this module (e.g. \"myapp\")."
  default     = null
}

variable "user_access_sns_topic_arn" {
  type        = string
  default     = null
  description = <<-EOT
    ARN of an existing SNS topic to publish notifications to.
    When set, the module will NOT create a new SNS topic and
    sns_email_subscriptions is ignored.
    When null (default), a new SNS topic is created by this module.
  EOT

  validation {
    condition     = var.user_access_sns_topic_arn == null || can(regex("^arn:[a-z0-9-]+:sns:", var.user_access_sns_topic_arn))
    error_message = "sns_topic_arn must be a valid SNS topic ARN (arn:<partition>:sns:...)."
  }
}

variable "user_access_sns_email_subscriptions" {
  type        = list(string)
  default     = []
  description = "List of e-mail addresses to subscribe to the SNS topic created by this module. Ignored when sns_topic_arn is provided."
}

variable "user_access_name_pattern" {
  type        = string
  default     = "*"
  description = "Glob pattern matched against IAM usernames (e.g. \"*Example*\"). Defaults to all users."
}

variable "user_access_tag_key" {
  type        = string
  default     = ""
  description = "Optional IAM tag key. When set, only users that carry this tag (with tag_value) are checked."
}

variable "user_access_tag_value" {
  type        = string
  default     = ""
  description = "Optional IAM tag value paired with tag_key."
}

variable "user_access_warning_days" {
  type        = number
  default     = 80
  description = "Publish a WARNING notification when a key is this many days old."

  validation {
    condition     = var.user_access_warning_days > 0
    error_message = "warning_days must be a positive integer."
  }
}

variable "user_access_alert_days" {
  type        = number
  default     = 90
  description = "Publish an ALERT notification when a key is this many days old. Must be >= warning_days."

  validation {
    condition     = var.user_access_alert_days > 0
    error_message = "alert_days must be a positive integer."
  }

}

variable "user_access_schedule_expression" {
  type        = string
  default     = "rate(1 day)"
  description = "EventBridge schedule expression. Defaults to once per day."
}
