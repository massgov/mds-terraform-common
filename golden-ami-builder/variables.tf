variable "software_distribution_bucket_id" {
  description = "Identifier of the S3 bucket used to distribute software required by Image Builder pipeline"
  type        = string
}

variable "software_distribution_bucket_key_arn" {
  description = "ARN of KMS key used to encrypt/decrypt files in the distribution bucket"
  type        = string
}

variable "volume_key_alias" {
  description = "Alias of KMS key used to encrypt EBS snapshots created by Image Builder pipeline"
  type        = string
  default     = "alias/aws/ebs"
}

variable "vpc_name" {
  description = "Name of VPC to use for Image Builder infrastructure configuration"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group identifiers to use for Image Builder infrastructure configuration. If null, an all-egress security group will be created (default: null)"
  type        = list(string)
  default     = null
}

variable "alerting_sns_topic_arn" {
  description = "ARN of the SNS topic to which pipeline alerts will be published (default: null)"
  type        = string
  default     = null
}

variable "pipeline_schedule_expression" {
  description = "Cron expression of how often, in UTC, the Image Builder pipeline start condition is evaluated (default: 'cron(0 6 1 * ? *)')"
  default     = "cron(0 6 1 * ? *)" # First day of every month, 6AM UTC
  type        = string
}

variable "tags" {
  description = <<EOF
    Map of key-value pairs used to tag resources created by this module. Provider-level default tags may not be applied to infrastructure as
    expected; make sure to explicitly pass in all desired tags (default: {})
  EOF
  type        = map(string)
  default     = {}
}