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
