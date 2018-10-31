
// Lambda function ARN.
output "function_arn" {
  value = "${aws_lambda_function.default.arn}"
}

// Lambda function name.
output "function_name" {
  value = "${aws_lambda_function.default.function_name}"
}