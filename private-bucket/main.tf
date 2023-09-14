resource "aws_s3_bucket" "default" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      "Name"               = var.bucket_name
      "dataclassification" = var.data_classification
      "public"             = "no"
    },
  )
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl = "private"

  depends_on = [aws_s3_bucket_ownership_controls.default]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.default.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
