locals {
  lambda_name = "itd-mgt-ecs-cluster-image-scan"
}

data "aws_iam_policy_document" "maintenance_ecs_scan_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks",
      "ecs:ListTasks",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"

      values = values(local.ecs_cluster_arns)
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:StartImageScan", "ecr:DescribeImageScanFindings"]
    resources = local.ecr_repository_arns
  }
}

resource "aws_iam_policy" "maintenance_ecs_scan_lambda" {
  name   = "maintenance-ecs-scan-lambda"
  policy = data.aws_iam_policy_document.maintenance_ecs_scan_lambda.json
}

module "ecs_cluster_image_scan" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.88"
  package    = "${path.module}/lambda/dist/lambda.zip"
  name       = local.lambda_name
  human_name = "SSR ECS Cluster Image Scan"
  handler    = "index.handler"
  runtime    = "nodejs20.x"
  iam_policy_arns = [
    aws_iam_policy.maintenance_publish_alerts.arn,
    aws_iam_policy.maintenance_ecs_scan_lambda.arn,
  ]
  error_topics = [aws_sns_topic.maintenance_notifications.arn]

  environment = {
    variables = {
      ERROR_TOPIC_ARN      = aws_sns_topic.maintenance_notifications.arn
      ALERT_SEVERITY_LEVEL = "CRITICAL"
    }
  }
  tags = {
    "Name" = local.lambda_name
  }
}

