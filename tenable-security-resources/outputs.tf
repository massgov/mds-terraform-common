output "lambda_name" {
  value = aws_lambda_function.remediator.function_name
}

output "runinstances_rule_name" {
  value = aws_cloudwatch_event_rule.runinstances.name
}

output "sg_change_rule_name" {
  value = aws_cloudwatch_event_rule.sg_change.name
}

output "lambda_arn" {
  value = aws_lambda_function.remediator.arn
}
