output "launch_template_arn" {
  value = aws_launch_template.default.arn
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