locals {
  region = coalesce(var.region, data.aws_region.current.name)
}

data "aws_region" "current" {}

resource "aws_ssm_document" "ssr_check_tableau_license" {
  name            = "SSR-CheckTableauLicenses"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/check_tableau_licenses.yml",
    {
      region           = local.region
      alerts_topic_arn = var.default_alerting_topic
    }
  )
}