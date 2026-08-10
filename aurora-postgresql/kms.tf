data "aws_iam_policy_document" "kms" {
  count = var.create_kms_key ? 1 : 0

  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "this" {
  count = var.create_kms_key ? 1 : 0

  description             = "Aurora PostgreSQL cluster ${var.name}."
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_kms_alias" "this" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/rds/${var.name}"
  target_key_id = aws_kms_key.this[0].key_id
}
