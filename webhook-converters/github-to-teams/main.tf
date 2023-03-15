data "aws_region" "default" {}

data "aws_caller_identity" "current" {}

locals {
  aws_region     = data.aws_region.default.name
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda/dist/lambda.js"
  output_path = "${path.module}/package/lambda.zip"
}

data "aws_iam_policy_document" "lambda_inline_policy" {
  statement {
    actions = [
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter${var.ssm_parameter_prefix}/teams-webhook",
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter${var.ssm_parameter_prefix}/github-secret",
    ]
  }
}

resource "random_password" "path_token" {
  length  = 50
  special = false
}

module "lambda" {
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.43"
  package = data.archive_file.lambda_package.output_path
  runtime = "nodejs12.x"
  handler = "lambda.default"
  environment = {
    variables = merge({
      CONFIGURABLE_PARAM_PREFIX = var.ssm_parameter_prefix
      MIN_LOG_LEVEL             = var.min_log_level
      SEND_TO_TEAMS             = var.send_to_teams ? "yes" : "no"
      PATH_TOKEN                = random_password.path_token.result
    }, var.environment_vars)
  }
  iam_policies = concat(
    [data.aws_iam_policy_document.lambda_inline_policy.json],
    var.iam_policies,
  )

  name            = var.name
  human_name      = var.human_name
  tags            = var.tags
  subnets         = var.subnets
  error_topics    = var.error_topics
  iam_policy_arns = var.iam_policy_arns
  memory_size     = var.memory_size
  security_groups = var.security_groups
  timeout         = var.timeout
}
