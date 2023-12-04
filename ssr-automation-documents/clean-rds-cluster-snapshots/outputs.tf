output "document_arn" {
  value = aws_ssm_document.ssr_clean_up_rds_cluster_snapshots.arn
}

output "latest_document_version" {
  value = aws_ssm_document.ssr_clean_up_rds_cluster_snapshots.latest_version
}