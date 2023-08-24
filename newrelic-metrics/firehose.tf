# https://docs.newrelic.com/docs/infrastructure/amazon-integrations/connect/aws-metric-stream-setup/
data "aws_caller_identity" "default" {
}


module "firehose_bucket" {
  source = "../private-bucket"
  bucket_name = "${var.name_prefix}-newrelic-firehose-data"
  tags = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "default" {
  name = "${var.name_prefix}-newrelic-firehose-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = var.newrelic_api_url
    name               = "New Relic"
    access_key         = var.newrelic_access_key
    buffering_size     = var.buffering_size
    buffering_interval = var.buffering_interval
    role_arn           = aws_iam_role.firehose_role.arn
    retry_duration     = var.retry_duration #60

    s3_backup_mode     = "FailedDataOnly"

    request_configuration {
      content_encoding = "GZIP"
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_logs.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_logs_http.arn
    }
  }

  # NOTE: When we upgrade the aws terraform provider to >=5, this needs to be
  # moved inside the http_endpoint_configuration
  s3_configuration {
    bucket_arn = module.firehose_bucket.bucket_arn
    role_arn   = aws_iam_role.firehose_role.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_logs.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_logs_s3.arn
    }
  }

  tags = var.tags
}


resource "aws_iam_role" "firehose_role" {
  name               = "${var.name_prefix}-newrelic-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    # https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#firehose-assume-role
    condition {
      test  = "StringEquals"
      variable = "sts:ExternalId"
      values = [data.aws_caller_identity.default.account_id]
    }
  }
}

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_policy.json
}

# https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-s3
data "aws_iam_policy_document" "firehose_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
     ]
     resources = [
       module.firehose_bucket.bucket_arn,
       "${module.firehose_bucket.bucket_arn}/*"
     ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_stream.firehose_logs_http.arn,
      aws_cloudwatch_log_stream.firehose_logs_s3.arn
    ]
  }
}

resource "aws_cloudwatch_log_group" "firehose_logs" {
  name              = "/kinesisfirehose/${var.name_prefix}-newrelic-firehose"
  retention_in_days = 30
  skip_destroy      = true # We don't have permission to delete these anyways.
  tags              = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-newrelic-firehose"
    }
  )
}

resource "aws_cloudwatch_log_stream" "firehose_logs_http" {
  name           = "http"
  log_group_name = aws_cloudwatch_log_group.firehose_logs.name
}

resource "aws_cloudwatch_log_stream" "firehose_logs_s3" {
  name           = "s3"
  log_group_name = aws_cloudwatch_log_group.firehose_logs.name
}
