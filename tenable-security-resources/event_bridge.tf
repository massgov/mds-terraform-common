resource "aws_cloudwatch_event_rule" "runinstances" {
  name        = "ec2-runinstances-remediation"
  description = "Catch new EC2 launches and ensure the scanner SG is attached."

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["RunInstances"]
    }
  })
}

resource "aws_cloudwatch_event_target" "runinstances_lambda" {
  rule      = aws_cloudwatch_event_rule.runinstances.name
  target_id = "RunInstancesToLambda"
  arn       = aws_lambda_function.remediator.arn
}

resource "aws_lambda_permission" "allow_runinstances" {
  statement_id  = "AllowEventBridgeRunInstances"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.runinstances.arn
}

resource "aws_cloudwatch_event_rule" "sg_change" {
  name        = "ec2-security-group-remediation"
  description = "Catch SG changes and re-attach the required scanner SG if it is missing."

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName = [
        "ModifyInstanceAttribute",
        "ModifyNetworkInterfaceAttribute"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "sg_change_lambda" {
  rule      = aws_cloudwatch_event_rule.sg_change.name
  target_id = "SecurityGroupChangeToLambda"
  arn       = aws_lambda_function.remediator.arn
}

resource "aws_lambda_permission" "allow_sg_change" {
  statement_id  = "AllowEventBridgeSecurityGroupChange"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sg_change.arn
}
