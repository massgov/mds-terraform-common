output "launch_template_arn" {
  value = aws_launch_template.default.arn
}

output "launch_template_latest_version" {
  value = aws_launch_template.default.latest_version
}

output "instance_id" {
  value = aws_instance.default.id
}

output "s3fs_bucket_id" {
  value = aws_s3_bucket.s3fs.id
}

output "s3fs_file_system_id" {
  value = aws_s3files_file_system.s3fs.id
}