output "plan_policy_json" {
  value = data.aws_iam_policy_document.policy_info["plan"].json
}

output "apply_policy_json" {
  value = data.aws_iam_policy_document.policy_info["apply"].json
}
