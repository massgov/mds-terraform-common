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

variable "rds_instance_names" {
  type        = list(string)
  description = "A list of RDS instance names we want to manage backups for"
  default     = null
}

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

variable "create_github_inactive_user_reminder" {
  type        = bool
  description = "Determines if the inactive github user reminder will be created"
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
