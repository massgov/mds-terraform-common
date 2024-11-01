data "aws_caller_identity" "identity" {}

resource "aws_sns_topic" "alerts" {
  name = var.topic_name
}

data "aws_iam_policy_document" "alerts" {
  statement {
    sid       = "AllowPublishingToAlertsTopic"
    effect    = "Allow"
    resources = [aws_sns_topic.alerts.arn]
    actions   = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.assume_role.arn]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts.json
}

resource "aws_cloudwatch_event_rule" "assume_role" {
  name        = var.topic_name
  description = "Provides notifications when certain roles are assumed."
  state       = "ENABLED"
  event_pattern = jsonencode({
    "detail" : {
      "eventName" : ["AssumeRole", "AssumeRoleWithSAML", "AssumeRoleWithWebIdentity"],
      "eventSource" : ["sts.amazonaws.com"],
      "requestParameters" : { "roleArn" : var.role_arns }
    },
    "detail-type" : ["AWS API Call via CloudTrail"],
    "source" : ["aws.sts"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  arn  = aws_sns_topic.alerts.arn
  rule = aws_cloudwatch_event_rule.assume_role.name
  input_transformer {
    input_paths = {
      "role" = "$.detail.requestParameters.roleArn",
      "user" = "$.detail.userIdentity.userName",
    }
    input_template = "\"<user> has assumed a role in account #${data.aws_caller_identity.identity.account_id}: <role>\""
  }
}
