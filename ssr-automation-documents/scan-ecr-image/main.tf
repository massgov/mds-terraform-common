locals {
  region = coalesce(var.region, data.aws_region.current.name)
  account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_ssm_document" "ssr_scan_ecr_image" {
  name            = "SSR-ScanECRImage"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/scan_ecr_image_document.yml",
    {
      region           = local.region
      account_id       = local.account_id
      alerts_topic_arn = var.default_alerting_topic
    }
  )
}
