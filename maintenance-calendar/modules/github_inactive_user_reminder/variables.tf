variable "sns_topic_arn" {
  description = "The SNS topic to send the reminder to"
  type = string
}
variable "publish_alerts_policy" {
  description = "An IAM policy that allows writing to the SNS topic"
  type = string
}
