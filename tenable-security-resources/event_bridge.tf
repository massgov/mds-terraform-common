resource "aws_cloudwatch_event_rule" "instance_running" {
  name        = "ec2-instance-running-remediation"
  description = "Catch EC2 instances entering running state and ensure the scanner SG is attached."

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running"]
    }
  })
}

resource "aws_cloudwatch_event_target" "instance_running_lambda" {
  rule      = aws_cloudwatch_event_rule.instance_running.name
  target_id = "InstanceRunningToLambda"
  arn       = aws_lambda_function.remediator.arn
}

resource "aws_lambda_permission" "allow_instance_running" {
  statement_id  = "AllowEventBridgeInstanceRunning"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.instance_running.arn
}

resource "aws_cloudwatch_event_rule" "sg_change" {
  name        = "ec2-security-group-remediation"
  description = "Catch any SG changes and re-attach the required scanner SG if it is missing."

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
