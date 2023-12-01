output "document_arn" {
  value = aws_ssm_document.ssr_scan_ecr_image.arn
}

output "latest_document_version" {
  value = aws_ssm_document.ssr_scan_ecr_image.latest_version
}