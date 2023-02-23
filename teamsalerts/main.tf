resource "aws_lambda_function" "sns_to_teams" {
  filename         = "${path.module}/lambda/dist/archive.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/dist/archive.zip")
  function_name    = var.name
  handler          = "lambda.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs12.x"
  environment {
    variables = {
      TOPIC_MAP         = jsonencode(var.topic_map)
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
    }
  }
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_sns_topic_subscription" "default" {
  count    = length(var.topic_map)
  endpoint = aws_lambda_function.sns_to_teams.arn
  protocol = "lambda"
  topic_arn = lookup(
    element(var.topic_map, count.index),
    "topic_arn"
  )
}

resource "aws_lambda_permission" "sns_to_teams" {
  count         = length(var.topic_map)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_to_teams.function_name
  principal     = "sns.amazonaws.com"
  source_arn = lookup(
    element(var.topic_map, count.index),
    "topic_arn"
  )
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/${aws_lambda_function.sns_to_teams.function_name}"
  tags = var.tags
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "log_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.lambda_logs.arn}:*"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "LambdaSNSToTeams"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_role_policy" "lambda" {
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.log_policy.json
}

