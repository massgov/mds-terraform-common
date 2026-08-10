locals {
  kms_key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_id
}

resource "aws_kms_key" "this" {
  count = var.create_kms_key ? 1 : 0

  description             = "Aurora PostgreSQL cluster ${var.name}."
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_kms_alias" "this" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/rds/${var.name}"
  target_key_id = aws_kms_key.this[0].key_id
}
