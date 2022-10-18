// Lambda function ARN.
output "function_arn" {
  value = module.monitor_lambda.function_arn
}

// Lambda function name.
output "function_name" {
  value = module.monitor_lambda.function_name
}

// Lambda function qualified ARN (includes current version string)
output "function_qualified_arn" {
  value = module.monitor_lambda.function_qualified_arn
}

// Lambda function version.
output "function_version" {
  value = module.monitor_lambda.function_version
}

// Developer IAM policy.
output "developer_policies" {
  value = module.monitor_lambda.developer_policies
}
