// Lambda function ARN.
output "function_arn" {
  value = module.lambda.function_arn
}

// Lambda function name.
output "function_name" {
  value = module.lambda.function_name
}

// Lambda function qualified ARN (includes current version string)
output "function_qualified_arn" {
  value = module.lambda.function_qualified_arn
}

// Lambda function version.
output "function_version" {
  value = module.lambda.function_version
}

// Developer IAM policy.
output "developer_policies" {
  value = module.lambda.developer_policies
}
