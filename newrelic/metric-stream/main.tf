resource "aws_cloudwatch_metric_stream" "default" {
  name          = "${var.name_prefix}-newrelic-metric-stream"
  role_arn      = aws_iam_role.metric_stream_role.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.default.arn
  output_format = "opentelemetry0.7"
  tags          = var.tags

  dynamic "include_filter" {
    for_each = var.include_filters

    content {
      namespace    = include_filter.value.namespace
      metric_names = include_filter.value.metric_names
    }
  }
}


// https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-metric-streams-trustpolicy.html
resource "aws_iam_role" "metric_stream_role" {
  name               = "${var.name_prefix}-newrelic-metric-stream-role"
  assume_role_policy = data.aws_iam_policy_document.metric_stream_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "metric_stream_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["streams.metrics.cloudwatch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role_policy" "metric_stream_policy" {
  role   = aws_iam_role.metric_stream_role.id
  policy = data.aws_iam_policy_document.metric_stream_policy.json
}

data "aws_iam_policy_document" "metric_stream_policy" {
  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.default.arn
    ]
  }
}
