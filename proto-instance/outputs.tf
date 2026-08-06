output "launch_template_arn" {
  value = aws_launch_template.default.arn
}

output "proto_id" {
  value = local.proto_id
}