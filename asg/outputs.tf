// The ID of the ASG.
output "autoscaling_group_id" {
  value = "${aws_autoscaling_group.default.id}"
}

// The developer policy
output "developer_policies" {
  value = ["${data.aws_iam_policy_document.developer.json}"]
}