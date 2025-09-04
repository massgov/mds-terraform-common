data "aws_cloudwatch_log_group" "log_group" {
  name = var.log_group_name
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = var.metric_filter_name
  log_group_name = data.aws_cloudwatch_log_group.log_group.name
  pattern        = var.metric_filter_pattern

  metric_transformation {
    name      = var.metric_name
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_sns_topic" "alert_topic" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.email_addresses)

  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_metric_alarm" "log_alarm" {
  alarm_name          = var.alarm_name
  metric_name         = var.metric_name
  namespace           = var.metric_namespace
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alert_topic.arn]
}