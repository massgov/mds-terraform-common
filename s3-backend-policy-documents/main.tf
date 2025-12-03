locals {
  # We're creating two policies - they only differ in s3:PutObject permissions
  # for the state file
  policy_info = {
    plan = {
      s3  = ["s3:GetObject"]
      kms = ["kms:Decrypt"]
    }
    apply = {
      s3  = ["s3:GetObject", "s3:PutObject"]
      kms = ["kms:Decrypt", "kms:GenerateDataKey"]
    }
  }
}

# https://developer.hashicorp.com/terraform/language/backend/s3#s3-bucket-permissions
data "aws_iam_policy_document" "policy_info" {
  # These policies differ only in whether or not the state file can be
  # written to.
  for_each = tomap(local.policy_info)

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]

    # https://developer.hashicorp.com/terraform/language/backend/s3#s3-bucket-permissions
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = var.state_file_paths
    }
  }
  statement {
    sid       = "AccessStateFile"
    actions   = each.value.s3
    resources = [for path in var.state_file_paths : "arn:aws:s3:::${var.bucket_name}/${path}"]
  }
  statement {
    sid       = "AccessLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for path in var.state_file_paths : "arn:aws:s3:::${var.bucket_name}/${path}.lock"]
  }
  statement {
    sid       = "BucketEncryption"
    actions   = each.value.kms
    resources = [var.bucket_kms_key]
  }
}
