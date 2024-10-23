data "aws_kms_alias" "ssm_key" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "read_parameter_store" {
  statement {
    actions = [
      "ssm:GetParameter",
    ]
    effect = "Allow"
    resources = var.teams_webhook_url_param_arn == null ? [] : [
      var.teams_webhook_url_param_arn
    ]
  }
  statement {
    actions = [
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      coalesce(
        var.teams_webhook_url_param_key,
        data.aws_kms_alias.ssm_key.target_key_arn
      )
    ]
    condition {
      test = "ArnLike"
      values = var.teams_webhook_url_param_arn == null ? [] : [
        var.teams_webhook_url_param_arn
      ]
      variable = "kms:EncryptionContext:PARAMETER_ARN"
    }
  }
}

resource "aws_iam_policy" "read_parameter_store" {
  count = var.teams_webhook_url_param_arn == null ? 0 : 1

  name   = "${var.name}-read-parameter-store"
  policy = data.aws_iam_policy_document.read_parameter_store.json
}

module "sns_to_teams" {
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.91"
  package = "${path.module}/lambda/dist/archive.zip"
  runtime = "nodejs20.x"
  handler = "lambda.handler"
  environment = {
    variables = {
      TOPIC_MAP                   = jsonencode(var.topic_map)
      TEAMS_WEBHOOK_URL           = var.teams_webhook_url
      TEAMS_WEBHOOK_URL_PARAM_ARN = var.teams_webhook_url_param_arn
    }
  }
  iam_policy_arns = [for p in aws_iam_policy.read_parameter_store : p.arn]
  name            = var.name
  human_name      = var.human_name
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    }
  )
  error_topics = var.error_topics
  memory_size  = var.memory_size
  timeout      = var.timeout
}

resource "aws_sns_topic_subscription" "default" {
  count    = length(var.topic_map)
  endpoint = module.sns_to_teams.function_arn
  protocol = "lambda"
  topic_arn = lookup(
    element(var.topic_map, count.index),
    "topic_arn"
  )
}

resource "aws_lambda_permission" "sns_to_teams" {
  count         = length(var.topic_map)
  action        = "lambda:InvokeFunction"
  function_name = module.sns_to_teams.function_name
  principal     = "sns.amazonaws.com"
  source_arn = lookup(
    element(var.topic_map, count.index),
    "topic_arn"
  )
}
