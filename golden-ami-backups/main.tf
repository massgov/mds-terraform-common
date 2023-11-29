locals {
  lambda_function_package = "${path.module}/lambda/dist/lambda.zip"
}

data "aws_kms_alias" "parameter_store" {
  name = var.parameter_store_key_alias
}

data "aws_kms_alias" "ebs" {
  name = var.ebs_key_alias
}

/**
 * Lambda Function:
 */

data "aws_iam_policy_document" "publish_errors" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.error_topic_arn]
  }
}

data "aws_iam_policy_document" "read_parameter" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      var.source_image_parameter_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      data.aws_kms_alias.parameter_store.target_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        var.source_image_parameter_arn
      ]
    }
  }
}

data "aws_iam_policy_document" "copy_image" {
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = [
      var.parent_account_ebs_key_arn,
      data.aws_kms_alias.ebs.target_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:GranteePrincipal"
      values   = ["ec2.us-east-1.amazonaws.com"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "kms:GrantOperations"
      values   = ["Encrypt", "Decrypt"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey"
    ]
    resources = [
      var.parent_account_ebs_key_arn,
      data.aws_kms_alias.ebs.target_key_arn
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["ec2:CopyImage"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "publish_errors" {
  name   = "${var.name_prefix}-publish-errors-to-sns"
  policy = data.aws_iam_policy_document.publish_errors.json
}

resource "aws_iam_policy" "read_parameter" {
  name   = "${var.name_prefix}-read-golden-ami-param"
  policy = data.aws_iam_policy_document.read_parameter.json
}

resource "aws_iam_policy" "copy_image" {
  name   = "${var.name_prefix}-copy-golden-ami"
  policy = data.aws_iam_policy_document.copy_image.json
}

module "golden_ami_backups" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.78"
  package    = local.lambda_function_package
  name       = "${var.name_prefix}-backup-lambda"
  human_name = var.human_name
  handler    = "index.handler"
  runtime    = "nodejs18.x"
  iam_policy_arns = [
    aws_iam_policy.publish_errors.arn,
    aws_iam_policy.read_parameter.arn,
    aws_iam_policy.copy_image.arn
  ]
  error_topics = [var.error_topic_arn]

  environment = {
    variables = {
      SOURCE_IMAGE_PARAMETER_ARN = var.source_image_parameter_arn
      ERROR_TOPIC_ARN            = var.error_topic_arn
      REENCRYPTION_KEY_ID        = data.aws_kms_alias.ebs.target_key_id
      DEST_IMAGE_PREFIX          = var.name_prefix
    }
  }
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-backup-lambda"
    },
  )
}

resource "aws_cloudwatch_event_rule" "golden_ami_backups" {
  name        = "${var.name_prefix}-parameter-updates"
  description = "Listen for updates to the Golden AMI parameter"

  event_pattern = jsonencode({
    source      = ["aws.ssm"],
    detail-type = ["Parameter Store Change"],
    resources   = [var.source_image_parameter_arn]
  })
}

resource "aws_cloudwatch_event_target" "golden_ami_backups" {
  rule = aws_cloudwatch_event_rule.golden_ami_backups.name
  arn  = module.golden_ami_backups.function_arn
}

resource "aws_lambda_permission" "golden_ami_backups" {
  statement_id  = "${var.name_prefix}-allow-cloudwatch-execution"
  action        = "lambda:InvokeFunction"
  function_name = module.golden_ami_backups.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.golden_ami_backups.arn
}
