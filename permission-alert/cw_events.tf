# EventBridge rule to react to any IAM changes that could elevate privileges
# While this detects changes to any role, the Lambda will filter to just the target role
resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "role-admin-detector-iam-events"
  description = "Trigger when IAM role/policy changes occur"

  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : [
        # Attach/detach/inline policy changes for roles
        "AttachRolePolicy",
        "DetachRolePolicy",
        "PutRolePolicy",
        "DeleteRolePolicy",
        # Managed policy lifecycle that could affect effective perms
        "CreatePolicy",
        "CreatePolicyVersion",
        "SetDefaultPolicyVersion",
        "DeletePolicyVersion",
        "CreatePolicyVersion",
        # Permissions boundary or trust changes (paranoid coverage)
        "PutRolePermissionsBoundary",
        "DeleteRolePermissionsBoundary",
        "UpdateAssumeRolePolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "to_lambda" {
  rule      = aws_cloudwatch_event_rule.iam_changes.name
  target_id = "role-admin-detector"
  arn       = aws_lambda_function.detector.arn
}
