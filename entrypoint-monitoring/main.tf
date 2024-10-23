data "aws_region" "default" {}

data "aws_caller_identity" "current" {}

locals {
  aws_region     = data.aws_region.default.name
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "archive_file" "monitor_package" {
  type        = "zip"
  source_file = "${path.module}/lambda/dist/lambda.js"
  output_path = "${path.module}/package/lambda.zip"
}

data "aws_iam_policy_document" "monitor_inline_policy" {
  statement {
    actions = [
      "sns:Publish"
    ]
    resources = [
      var.report_topic_arn
    ]
  }

  statement {
    actions = [
      "cloudfront:ListDistributions",
      "elasticloadbalancing:DescribeLoadBalancers",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "s3:ListAllMyBuckets",
      "s3:GetBucketWebsite",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "apigateway:GET",
    ]
    resources = [
      "arn:aws:apigateway:${local.aws_region}::/restapis",
      "arn:aws:apigateway:${local.aws_region}::/domainnames",
      "arn:aws:apigateway:${local.aws_region}::/domainnames/*/basepathmappings",
      "arn:aws:apigateway:${local.aws_region}::/apis",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter${var.allowed_points_parameter}"
    ]
  }
}

module "monitor_lambda" {
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.91"
  package = data.archive_file.monitor_package.output_path
  runtime = "nodejs20.x"
  handler = "lambda.default"
  environment = {
    variables = merge({
      ALLOWED_POINTS_PARAMETER = var.allowed_points_parameter
      MIN_LOG_LEVEL            = var.min_log_level
      REPORT_SNS_TOPIC         = var.report_topic_arn
    }, var.environment_vars)
  }
  iam_policies = concat(
    [data.aws_iam_policy_document.monitor_inline_policy.json],
    var.iam_policies,
  )

  name            = var.name
  human_name      = var.human_name
  tags            = var.tags
  subnets         = var.subnets
  schedule        = var.schedule
  error_topics    = var.error_topics
  iam_policy_arns = var.iam_policy_arns
  memory_size     = var.memory_size
  security_groups = var.security_groups
  timeout         = var.timeout
}
