
# ---------------------------------------------------------------------------
# SNS topic — created only when no external ARN is supplied
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "this" {
  count = var.sns_topic_arn == null ? 1 : 0

  name = local.module_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.sns_topic_arn == null ? toset(var.sns_email_subscriptions) : toset([])

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# ---------------------------------------------------------------------------
# IAM role for Lambda
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_permissions" {

  # IAM – read-only
  statement {
    sid    = "AllowIAMRead"
    effect = "Allow"
    actions = [
      "iam:ListUsers",
      "iam:ListAccessKeys",
      "iam:ListUserTags",
    ]
    resources = ["*"]
  }

  # SNS – publish
  statement {
    sid       = "AllowSNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [local.effective_sns_topic_arn]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.module_name}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_permissions.json
  tags   = var.tags
}


# ---------------------------------------------------------------------------
# Lambda function module
# ---------------------------------------------------------------------------
module "lambda" {
  source          = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.132"
  name            = local.module_name
  human_name      = "Checks IAM access key ages and sends SNS WARNING/ALERT notifications"
  handler         = "handler,lambda_handler"
  runtime         = "python3.12"
  iam_policy_arns = [aws_iam_policy.lambda.arn]
  package         = "${path.module}/lambda/src/handler.zip"
  environment = {
    variables = {
      SNS_TOPIC_ARN = local.effective_sns_topic_arn
      WARNING_DAYS  = tostring(var.warning_days)
      ALERT_DAYS    = tostring(var.alert_days)
      NAME_PATTERN  = var.name_pattern
      TAG_KEY       = var.tag_key
      TAG_VALUE     = var.tag_value
    }
  }
  tags = {
    "Name" = local.module_name
  }
}

# ---------------------------------------------------------------------------
# EventBridge (CloudWatch Events) scheduled rule
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = local.module_name
  description         = "Triggers IAM key age check on schedule"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "iam-key-notifier-lambda"
  arn       = module.lambda.function_arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
