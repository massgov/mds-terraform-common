output "chamber_read_arn" {
  value = aws_iam_policy.chamber_read.arn
}

output "logging_write_arn" {
  value = aws_iam_policy.logging_write.arn
}

output "ecr_readwrite_arn" {
  value = aws_iam_policy.ecr_readwrite.arn
}
