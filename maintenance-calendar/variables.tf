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
