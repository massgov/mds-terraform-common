data "aws_iam_policy_document" "state_sse_policy" {
  count = var.use_kms_key ? 1 : 0
  statement {
    sid     = "Allow management by account"
    actions = ["kms:*"]
    // Since it's attached directly, this wildcard only applies to the specific key.
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "state_sse" {
  count                   = var.use_kms_key ? 1 : 0
  description             = "SSE KMS key for Terraform state bucket: ${local.state_bucket_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state_sse_policy[0].json
  tags = {
    Name = var.kms_key_name
  }
}
