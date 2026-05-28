locals {
  module_name = "${var.name_prefix}-iam-key-notifier"

  # When sns_topic_arn is supplied, use it directly.
  # Otherwise fall back to the topic we created.
  effective_sns_topic_arn = coalesce(var.sns_topic_arn, one(aws_sns_topic.this[*].arn))

}