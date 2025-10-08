output "ebs_volume_arn" {
  value = "arn:aws:ec2:${local.region}:${local.account}:volume/${local.user_volume_id}"
}

output "launch_template_arn" {
  value = aws_launch_template.default.arn
}

output "proto_id" {
  value = local.proto_id
}