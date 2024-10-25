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
  description = <<EOF
    ARN of an SSM parameter containing CVEs that can safely be ignored.
    This parameter must be created manually if it doesn't already exist.
    
    Parameter format: `[{"name":"CVE-2024-1", "packageName":"cowsay", "packageVersion":["1.2.3", "1.2.4"]},{"name"...}]`
  EOF
}

variable "image_scan_snooze_arn" {
  type        = string
  description = <<EOF
    ARN of an SSM parameter containing ECS cluster names and a date to snooze alerts.
    This parameter must be created manually if it doesn't already exist.
    
    Parameter format: `[{"cluster":"ecs-cluster-1", "date":"2024-10-24"},{"cluster"...}]`
  EOF
}

variable "sns_topic_arn" {
  description = "The SNS topic to send alerts to"
  type        = string
}
variable "publish_alerts_policy" {
  description = "An IAM policy that allows writing to the SNS topic"
  type        = string
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "account_id" {
  type        = string
  description = "The AWS account ID"
}
