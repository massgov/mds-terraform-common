# Create a random id
resource "random_id" "bucket_id" {
  byte_length = 8
}

locals {
  bucket_root_name = var.guarantee_uniqueness ? "${var.bucket_name}-${random_id.bucket_id.dec}" : var.bucket_name
}

#############################################################################
# KMS Key for server-side encryption of bucket objects
#############################################################################

# Only create if var.kms_encrypted = true
resource "aws_kms_key" "s3_key" {
  count                   = (var.kms_key_arn == "" && var.kms_encrypted) ? 1 : 0
  description             = "This key is used to encrypt bucket objects in ${local.bucket_root_name} and ${local.bucket_root_name}-logs"
  deletion_window_in_days = 15 # Length of time the key will be retained when a deletion is scheduled.
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3_key_alias" {
  count         = (var.kms_key_arn == "" && var.kms_encrypted) ? 1 : 0
  name          = "alias/${local.bucket_root_name}"
  target_key_id = aws_kms_key.s3_key[0].arn
}

data "aws_kms_key" "s3_key_arn" {
  count  = var.kms_encrypted && var.kms_key_arn != "" ? 1 : 0
  key_id = (var.kms_key_arn == "" && var.kms_encrypted) ? aws_kms_key.s3_key[0].arn : var.kms_key_arn
}

#############################################################################
# Logging bucket (if enabled)
#############################################################################

# Only create if var.enable_logging = true
resource "aws_s3_bucket" "log_bucket" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${local.bucket_root_name}-logs"
}

resource "aws_s3_bucket_logging" "default_bucket_logging" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.default_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = var.log_prefix
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}


#############################################################################
# Default S3 Bucket
#############################################################################

# If bucket is NOT important, force_destroy = true; force-destroyed bucket contents are not recoverable!
resource "aws_s3_bucket" "default_bucket" {
  bucket        = local.bucket_root_name
  tags          = var.bucket_tags
  force_destroy = var.important ? false : true
}

resource "aws_s3_bucket_acl" "default_bucket_acl" {
  bucket = aws_s3_bucket.default_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "default_bucket_policy" {
  bucket = aws_s3_bucket.default_bucket.id
  policy = data.aws_iam_policy_document.default_bucket_policy.json
}

# Only used if var.kms_encrypted = true
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_sse_config" {
  count  = var.kms_encrypted ? 1 : 0
  bucket = aws_s3_bucket.default_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = (var.kms_key_arn == "" && var.kms_encrypted) ? aws_kms_key.s3_key[0].arn : var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Only used if var.kms_encrypted = false (which is the default value)
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_aes_config" {
  count  = var.kms_encrypted ? 0 : 1
  bucket = aws_s3_bucket.default_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# If bucket is important, turn on versioning
resource "aws_s3_bucket_versioning" "default_bucket_versioning" {
  bucket = aws_s3_bucket.default_bucket.id
  count  = var.important ? 1 : 0
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "default_bucket_policy" {
  # HTTPS only for all actions on this bucket
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.default_bucket.arn,
      "${aws_s3_bucket.default_bucket.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Optional extra statement when var.custom_policy != ""
  dynamic "statement" {
    for_each = var.custom_policy != "" ? [jsondecode(var.custom_policy)] : []
    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      # principals can be one object OR a list of objects
      dynamic "principals" {
        for_each = contains(keys(statement.value), "principals") ? (can(statement.value.principals[0]) ? statement.value.principals :
        [statement.value.principals]) : []

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      # condition can be single condition or list of conditions
      dynamic "condition" {
        for_each = contains(keys(statement.value), "conditions") ? statement.value.conditions : (
          contains(keys(statement.value), "condition")
          ? [statement.value.condition]
          : []
        )

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}
