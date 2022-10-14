data "aws_region" "default" {}

data "archive_file" "monitor_package" {
  type        = "zip"
  output_path = "${path.module}/package/lambda.zip"
  source {
    content  = "${path.module}/lambda/dist/lambda.js"
    filename = "lambda.js"
  }
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
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "apigateway:GET",
    ]
    resources = [
      "arn:aws:apigateway:${data.aws_region.default.name}::/restapis",
      "arn:aws:apigateway:${data.aws_region.default.name}::/domainnames",
      "arn:aws:apigateway:${data.aws_region.default.name}::/domainnames/*/basepathmappings",
      "arn:aws:apigateway:${data.aws_region.default.name}::/apis",
    ]
  }
}

module "monitor_lambda" {
  source                 = "../lambda"
  package                = data.archive_file.monitor_package.output_path
  runtime                = "nodejs14.x"
  handler                = "lambda.handler"
  ephemeral_storage_size = 0
  environment = {
    variables = merge({
      ALLOWED_POINTS_PARAMETER = var.allowed_points_parameter
      MIN_LOG_LEVEL            = var.min_log_level
      REPORT_SNS_TOPIC         = var.report_topic_arn
    }, var.environment_vars)
  }
  iam_policies = concat(
    data.aws_iam_policy_document.monitor_inline_policy.json,
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
