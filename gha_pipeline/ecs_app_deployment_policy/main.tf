data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  region = coalesce(var.region, data.aws_region.current.name)
  account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)
  secrets_namespace = "tf/${var.namespace}"
}

resource "aws_iam_policy" "chamber_read" {
  name = "${var.project_name}-deployment-chamber-policy"
  description = "Policy for ${var.project_name} chamber access."
  policy = data.aws_iam_policy_document.access_chamber_params.json
}

resource "aws_iam_policy" "logging_write" {
  name = "${var.project_name}-deployment-logging-policy"
  description = "Policy for ${var.project_name} logging."
  policy = data.aws_iam_policy_document.logging.json
}

resource "aws_iam_policy" "ecr_readwrite" {
  name = "${var.project_name}-deployment-ecr-policy"
  description = "Policy for ${var.project_name} ecr access."
  policy = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "access_chamber_params" {
  statement {
    actions = [
      "kms:ListKeys",
      "kms:ListAliases",
      "kms:Describe*",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      var.chamber_key
    ]
  }
  statement {
    actions = [
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:*:${local.account_id}:parameter/${local.secrets_namespace}/*",
      "arn:aws:ssm:${local.region}:${local.account_id}:parameter/infrastructure/ci-decryption",
    ]
  }
}

data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/codebuild/${var.logging_namespace}*:*",
    ]
  }
}

data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    effect = "Allow"
    resources = [
      for ecr_resource in var.ecr_resources : "arn:aws:ecr:${local.region}:${local.account_id}:repository/${ecr_resource}"
    ]
  }
}

