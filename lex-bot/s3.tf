resource "aws_s3_bucket" "source_bucket" {
  for_each = toset(var.environments)
  bucket   = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-knowledge-base-data"

  tags = {
    Name = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-knowledge-base-data"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  for_each = toset(var.environments)
  bucket                  = aws_s3_bucket.source_bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}