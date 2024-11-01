resource "aws_sns_topic" "this" {
  name = "${var.name_prefix}-ssm-session-alerts"
}

resource "aws_cloudwatch_event_rule" "this" {
  name        = "${var.name_prefix}-monitor-ssm-sessions"
  description = "Capture AWS Session Manager session activity"

  event_pattern = jsonencode({
    source = ["aws.ssm"],
    detail-type = [
      "AWS API Call via CloudTrail",
    ],
    detail = {
      eventSource = ["ssm.amazonaws.com"],
      eventName = [
        "StartSession",
        "ResumeSession",
        # TerminateSession has occasionally triggered from the CLI, and
        # in the console when you click the "Terminate Session" button.
        # I don't know if this is actually useful information?
        "TerminateSession"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule = aws_cloudwatch_event_rule.this.name
  arn  = aws_sns_topic.this.arn

  input_transformer {
    input_paths = {
      # `userIdentity.arn` gets identifiable information for both IAM and SSO users
      "user"     = "$.detail.userIdentity.arn"
      "target"   = "$.detail.requestParameters.target"
      "document" = "$.detail.requestParameters.documentName"
      "action"   = "$.detail.eventName"
    }

    # Target will be empty for TerminateSession, maybe ResumeSession too...
    # Document will be empty if a document is not specified, or the browser
    # session is used.
    input_template = "\"'<user>' performed session action '<action>' with target '<target>' (optional document = '<document>')\""
  }
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
