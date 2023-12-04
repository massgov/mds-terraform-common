output "document_arn" {
  value = aws_ssm_document.ssr_run_tableau_maintenance.arn
}

output "latest_document_version" {
  value = aws_ssm_document.ssr_run_tableau_maintenance.latest_version
}