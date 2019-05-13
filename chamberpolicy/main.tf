

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_kms_alias" "chamber_key" {
  name = "${var.key_alias}"
}
locals {
  region = "${coalesce(var.region, data.aws_region.current.name)}"
  account_id = "${coalesce(var.account_id, data.aws_caller_identity.current.account_id)}"
  parameter_arn = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.namespace}"
}

data "aws_iam_policy_document" "read_policy" {
  statement {
    sid = "Allow read access to SSM"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = ["${local.parameter_arn}"]
  }
  statement {
    sid = "Allow decrypt access to KMS"
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
    sid = "Allow read/write access to SSM"
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
    sid = "Allow decrypt access to KMS"
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
    sid = "Allow encrypt access to KMS"
    actions = ["kms:Encrypt"]
    resources = ["${data.aws_kms_alias.chamber_key.arn}"]
  }
}
