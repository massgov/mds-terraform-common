output "pike_self_manage_policy_arn" {
  description = "ARN of the Pike self-manage policy"
  value       = aws_iam_policy.pike_self_manage.arn
}

output "deploy_least_privilege_policy_arns" {
  description = "Map of least-privilege policy ARNs generated from Pike policy files"
  value       = { for k, v in aws_iam_policy.deploy_least_privilege : k => v.arn }
}

output "deploy_least_privilege_policy_names" {
  description = "Map of least-privilege policy names generated from Pike policy files"
  value       = { for k, v in aws_iam_policy.deploy_least_privilege : k => v.name }
}

output "deploy_least_privilege_policy_ids" {
  description = "Map of least-privilege policy IDs generated from Pike policy files"
  value       = { for k, v in aws_iam_policy.deploy_least_privilege : k => v.id }
}

output "project_key" {
  description = "Unique project key derived from the current apply role name"
  value       = local.project_key
}

output "pike_policy_files" {
  description = "Set of policy files found with the specified prefix"
  value       = local.policy_files
}

output "pike_attached_policy_arns" {
  description = "List of all policy ARNs attached to the role"
  value = concat(
    [aws_iam_policy.pike_self_manage.arn],
    [for p in aws_iam_policy.deploy_least_privilege : p.arn]
  )
}
