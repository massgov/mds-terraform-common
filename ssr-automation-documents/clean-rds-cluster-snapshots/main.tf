locals {
  region = coalesce(var.region, data.aws_region.current.name)
}

data "aws_region" "current" {}

resource "aws_ssm_document" "ssr_clean_up_rds_cluster_snapshots" {
  name            = "SSR-CleanUpRDSClusterSnapshots"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/clean_up_rds_cluster_snapshots.yml",
    {
      region           = local.region
      alerts_topic_arn = var.default_alerting_topic
    }
  )
}
