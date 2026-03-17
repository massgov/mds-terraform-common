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

resource "aws_iam_role" "newrelic_integration_role" {
  count              = var.newrelic_iam_role_arn == null ? 1 : 0
  name               = "${var.name_prefix}-newrelic-integration-role"
  assume_role_policy = data.aws_iam_policy_document.newrelic_integration_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "readonly_attachment" {
  count      = var.newrelic_iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.newrelic_integration_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
