module "sns_to_teams" {
  # TODO: change branch to tag before deploying
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=DP-27416-terraform-upgrade-0.13"
  package = "${path.module}/lambda/dist/archive.zip"
  runtime = "nodejs12.x"
  handler = "lambda.handler"
  environment = {
    variables = {
      TOPIC_MAP         = jsonencode(var.topic_map)
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
    }
  }
  iam_policies = []
  name         = var.name
  human_name   = var.human_name
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
