resource "aws_ssm_document" "ssr_run_tableau_maintenance" {
  name            = "SSR-RunTableauMaintenance"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/run_tableau_maintenance.yml",
    {
      alerts_topic_arn = var.default_alerting_topic
    }
  )
}