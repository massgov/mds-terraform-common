output "lambda_function_name" {
  description = "The name of the Lambda function monitoring IAM roles."
  value       = aws_lambda_function.detector.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function monitoring IAM roles."
  value       = aws_lambda_function.detector.arn
}

output "lambda_execution_role_name" {
  description = "The name of the IAM role assumed by the Lambda function."
  value       = aws_iam_role.detector_lambda.name
}

output "lambda_execution_role_arn" {
  description = "The ARN of the IAM role assumed by the Lambda function."
  value       = aws_iam_role.detector_lambda.arn
}

output "eventbridge_rule_arn" {
  description = "The ARN of the EventBridge rule for IAM changes."
  value       = aws_cloudwatch_event_rule.iam_changes.arn
}

output "eventbridge_target_id" {
  description = "The ID of the EventBridge target linking the rule to the Lambda."
  value       = aws_cloudwatch_event_target.to_lambda.target_id
}

output "sns_topic_arn" {
  description = "The SNS topic ARN used for alert notifications."
  value       = var.sns_topic_arn
}

output "monitored_role_names" {
  description = "The IAM Role names being monitored for admin privileges."
  value       = var.role_names
}
