

data "aws_caller_identity" "identity" {}
data "aws_region" "region" {}
data "aws_kms_alias" "chamber_key" {
  name = "${var.key_alias}"
}
locals {
  region = "${coalesce(var.region, data.aws_region.region.current)}"
  account_id = "${coalesce(var.account_id, data.aws_caller_identity.identity.account_id)}"
  parameter_arn = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.namespace}"
}

data "aws_iam_policy_document" "read_policy" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = ["${local.parameter_arn}"]
  }
  statement {
    actions = ["kms:Decrypt"]
    resources = ["${data.aws_kms_alias.chamber_key.arn}"]
    condition {
      test = "StringEquals"
      values = ["${local.parameter_arn}"]
      variable = "kms:EncryptionContext:PARAMETER_ARN"
    }
  }
}

data "aws_iam_policy_document" "readwrite_policy" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters"
    ]
  }
  // Read (decrypt)
  statement {
    actions = ["kms:Decrypt"]
    resources = ["${data.aws_kms_alias.chamber_key.arn}"]
    condition {
      test = "StringEquals"
      values = ["${local.parameter_arn}"]
      variable = "kms:EncryptionContext:PARAMETER_ARN"
    }
  }
  // Write (encrypt)
  statement {
    actions = ["kms:Encrypt"]
    resources = ["${data.aws_kms_alias.chamber_key.arn}"]
  }
}
