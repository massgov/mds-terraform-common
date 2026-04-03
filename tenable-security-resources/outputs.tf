output "lambda_name" {
  value = aws_lambda_function.remediator.function_name
}

output "instance_running_rule_name" {
  value = aws_cloudwatch_event_rule.instance_running.name
}

output "sg_change_rule_name" {
  value = aws_cloudwatch_event_rule.sg_change.name
}

output "lambda_arn" {
  value = aws_lambda_function.remediator.arn
}

output "ssm_document_name" {
  value       = aws_ssm_document.scanner_bootstrap.name
  description = "Name of the SSM document used for scanner bootstrap"
}

output "ec2_scanner_policy_arn" {
  value       = aws_iam_policy.ec2_scanner_access.arn
  description = "ARN of the scanner access policy that is automatically attached to EC2 instance roles"
}

output "ec2_scanner_policy_json" {
  value       = data.aws_iam_policy_document.ec2_scanner_access.json
  description = "policy document in json for scanner access"
}

output "discovered_instance_profile_names" {
  value       = local.unique_instance_profile_names
  description = "list of EC2 instance profile names discovered at deployment time"
}

output "discovered_role_names" {
  value       = local.unique_role_names
  description = "list of IAM role names that had the scanner policy attached at deployment time"
}
