output "sns_topic_arn" {
  value = aws_sns_topic.alert_topic.arn
}

output "aws_cloudwatch_metric_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.log_alarm.arn
}