output "document_arn" {
  value = aws_ssm_document.ssr_check_tableau_license.arn
}

output "latest_document_version" {
  value = aws_ssm_document.ssr_check_tableau_license.latest_version
}