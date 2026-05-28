output "sns_topic_arn" {
  description = "ARN of the SNS topic used for key-age notifications (created by this module or passed in via sns_topic_arn)."
  value       = local.effective_sns_topic_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda.function_arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule that triggers the Lambda."
  value       = aws_cloudwatch_event_rule.schedule.arn
}