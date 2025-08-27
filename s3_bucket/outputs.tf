output "full_bucket_name" {
  value = aws_s3_bucket.default_bucket.id
}

output "full_bucket_arn" {
  value = aws_s3_bucket.default_bucket.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}

output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

output "kms_key_arn" {
  value = var.kms_encrypted ? (var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.s3_key[0].arn) : ""
}
