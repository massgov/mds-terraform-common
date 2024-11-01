variable "rds_instance_names" {
  type        = list(string)
  description = "A list of RDS instance names we want to manage backups for"
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
