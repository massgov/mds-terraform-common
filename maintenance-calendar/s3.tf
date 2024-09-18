//This bucket doesn't have anything in it

resource "aws_s3_bucket" "maintenance_logs" {
  bucket = var.maintenance_logs_bucket

  tags = merge(
    var.tags,
    {
      "Name"        = var.maintenance_logs_bucket
      "application" = "massgov"
      "public"      = "no"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "maintenance_logs" {
  bucket = aws_s3_bucket.maintenance_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "maintenance_logs_versioning" {
  bucket = aws_s3_bucket.maintenance_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "maintenance_logs_owner" {
  bucket = aws_s3_bucket.maintenance_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "maintenance_logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.maintenance_logs_owner]

  bucket = aws_s3_bucket.maintenance_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "maintenance_logs_lifecycle" {
  bucket = aws_s3_bucket.maintenance_logs.id
  rule {
    id = "log-expiration"
    expiration {
      days = 366
    }
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "maintenance_logs_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:Put*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.maintenance_logs.arn,
      "${aws_s3_bucket.maintenance_logs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "maintenance_logs_bucket" {
  name   = "maintenance-logs-bucket"
  policy = data.aws_iam_policy_document.maintenance_logs_bucket.json
}