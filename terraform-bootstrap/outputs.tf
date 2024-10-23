output "state_bucket_arn" {
  value       = aws_s3_bucket.state.arn
  description = "ARN of the S3 bucket used to store Terraform state"
}

output "state_bucket_name" {
  value       = aws_s3_bucket.state.bucket
  description = "Name of the S3 bucket used to store Terraform state"
}

output "lock_table_arn" {
  value       = aws_dynamodb_table.lock.arn
  description = "ARN of the DynamoDB table used to store Terraform state lock"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.lock.name
  description = "Name of the DynamoDB table used to store Terraform state lock"
}

output "plan_policy_arn" {
  value       = one(aws_iam_policy.plan.*.arn)
  description = "ARN of the IAM policy used to plan Terraform state"
}

output "apply_policy_arn" {
  value       = one(aws_iam_policy.apply.*.arn)
  description = "ARN of the IAM policy used to apply Terraform state"
}
