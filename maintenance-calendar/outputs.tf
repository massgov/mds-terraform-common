output "notifications_topic_arn" {
  value = aws_sns_topic.maintenance_notifications.arn
}
output "iam_rotate_sns_topic_arn" {
  value = try(module.iam_user_access_key_age[0].sns_topic_arn, null)
}