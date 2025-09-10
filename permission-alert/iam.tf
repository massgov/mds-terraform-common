data "aws_iam_policy_document" "detector_lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "detector_lambda" {
  name               = "iam-admin-detector-role"
  assume_role_policy = data.aws_iam_policy_document.detector_lambda_assume.json
}

# Permissions for:
# - Reading IAM role policies (attached + inline)
# - Publishing to SNS
# - Writing CloudWatch Logs
data "aws_iam_policy_document" "detector_permissions" {
  statement {
    sid    = "IamRead"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AllowPublishToTopic"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "detector_inline" {
  name   = "iam-admin-detector-inline"
  policy = data.aws_iam_policy_document.detector_permissions.json
}

resource "aws_iam_role_policy_attachment" "detector_inline_attach" {
  role       = aws_iam_role.detector_lambda.name
  policy_arn = aws_iam_policy.detector_inline.arn
}
