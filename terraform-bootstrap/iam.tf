data "aws_iam_policy_document" "plan" {
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.lock.arn]
  }
  statement {
    sid = "S3List"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.state.arn]
  }
  statement {
    sid = "S3ObjectAccess"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
  dynamic "statement" {
    for_each = var.use_kms_key ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = [aws_kms_key.state_sse[0].arn]
    }
  }
}

resource "aws_iam_policy" "plan" {
  count       = var.create_plan_policy ? 1 : 0
  name        = "${local.state_bucket_name}-plan-policy"
  path        = var.iam_policy_path
  description = "Allows Terraform plan for the ${local.state_bucket_name} bucket"
  policy      = data.aws_iam_policy_document.plan.json
  tags = {
    Name = "${local.state_bucket_name}-plan-policy"
  }
}

data "aws_iam_policy_document" "apply" {
  source_policy_documents = [data.aws_iam_policy_document.plan.json]
  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  dynamic "statement" {
    for_each = var.use_kms_key ? [1] : []
    content {
      actions = [
        "kms:Encrypt",
      ]
      resources = [aws_kms_key.state_sse[0].arn]
    }
  }
}

resource "aws_iam_policy" "apply" {
  count       = var.create_apply_policy ? 1 : 0
  name        = "${local.state_bucket_name}-apply-policy"
  path        = var.iam_policy_path
  description = "Allows Terraform apply for the ${local.state_bucket_name} bucket"
  policy      = data.aws_iam_policy_document.apply.json
  tags = {
    Name = "${local.state_bucket_name}-apply-policy"
  }
}
