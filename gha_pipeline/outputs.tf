output "iam_role_name" {
  value       = aws_iam_role.role.name
  description = "value of the IAM role name created for the GitHub Actions pipeline"
}

output "iam_role_arn" {
  value       = aws_iam_role.role.arn
  description = "ARN of the IAM role created for the GitHub Actions pipeline"
}

output "policy_attachment_ids" {
  value       = [for a in aws_iam_role_policy_attachment.policy_attachments : a.id]
  description = "List of policy attachment IDs for the IAM role"
}
