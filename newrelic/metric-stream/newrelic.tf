resource "newrelic_cloud_aws_link_account" "default" {
  arn                    = aws_iam_role.newrelic_integration_role.arn
  metric_collection_mode = "PUSH"
  name                   = var.newrelic_aws_account_name
  account_id             = var.newrelic_account_id
}

resource "aws_iam_role" "newrelic_integration_role" {
  name               = "${var.name_prefix}-newrelic-integration-role"
  assume_role_policy = data.aws_iam_policy_document.newrelic_integration_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "newrelic_integration_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      # New Relic's AWS account id - from https://docs.newrelic.com/docs/infrastructure/amazon-integrations/connect/connect-aws-new-relic-infrastructure-monitoring/#connect
      identifiers = [754728514883]
    }

    # Make sure the "ExternalId" matches the New Relic account id.
    condition {
      test     = "StringEquals"
      values   = [var.newrelic_account_id]
      variable = "sts:ExternalId"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "newrelic_integration_policy" {
  role   = aws_iam_role.newrelic_integration_role.id
  policy = data.aws_iam_policy_document.newrelic_integration_policy.json
}

data "aws_iam_policy_document" "newrelic_integration_policy" {
  statement {
    effect = "Allow"
    # Required permissions from https://docs.newrelic.com/docs/infrastructure/amazon-integrations/get-started/integrations-managed-policies/#list-permissions
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      # I thought I saw somewhere that the config: roles weren't actually required,
      # but now I can't find it. We could try removing them once we have this working?
      "config:BatchGetResourceConfig",
      "config:ListDiscoveredResources",
      "tag:GetResources"
    ]

    resources = ["*"]
  }
}
