output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "The SNS topic ARN to which alerts will be published."
}
