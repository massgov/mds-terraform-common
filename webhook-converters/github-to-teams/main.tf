# TODO Drop it if not needed.
data "aws_region" "default" {}

# TODO Drop it if not needed.
data "aws_caller_identity" "current" {}

# TODO Drop it if not needed.
locals {
  aws_region = data.aws_region.default.name
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda/dist/lambda.js"
  output_path = "${path.module}/package/lambda.zip"
}

# TODO Drop it if not needed.
data "aws_iam_policy_document" "lambda_inline_policy" {
#  statement {
#    actions = [
#      "sns:Publish"
#    ]
#    resources = [
#      var.report_topic_arn
#    ]
#  }
#
#  statement {
#    actions = [
#      "cloudfront:ListDistributions",
#      "elasticloadbalancing:DescribeLoadBalancers",
#      "route53:ListHostedZones",
#      "route53:ListResourceRecordSets",
#      "s3:ListAllMyBuckets",
#      "s3:GetBucketWebsite",
#    ]
#    resources = ["*"]
#  }
#
#  statement {
#    actions = [
#      "apigateway:GET",
#    ]
#    resources = [
#      "arn:aws:apigateway:${local.aws_region}::/restapis",
#      "arn:aws:apigateway:${local.aws_region}::/domainnames",
#      "arn:aws:apigateway:${local.aws_region}::/domainnames/*/basepathmappings",
#      "arn:aws:apigateway:${local.aws_region}::/apis",
#    ]
#  }
#
#  statement {
#    actions = [
#      "ssm:GetParameter",
#    ]
#    resources = [
#      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter${var.allowed_points_parameter}"
#    ]
#  }
}

module "lambda" {
  source                 = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.26"
  package                = data.archive_file.lambda_package.output_path
  runtime                = "nodejs12.x"
  handler                = "lambda.default"
  environment = {
    variables = var.environment_vars
  }
  iam_policies = concat(
    [data.aws_iam_policy_document.lambda_inline_policy.json],
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
