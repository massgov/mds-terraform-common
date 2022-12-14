output "bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_arns" {
  value = aws_cloudfront_distribution.domain_distribution[*].arn
}
