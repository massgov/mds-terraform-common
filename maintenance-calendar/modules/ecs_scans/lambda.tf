locals {
  lambda_name = "itd-mgt-ecs-cluster-image-scan"
}

module "ecs_cluster_image_scan" {
  source     = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.88"
  package    = "${path.module}/lambda/dist/lambda.zip"
  name       = local.lambda_name
  human_name = "SSR ECS Cluster Image Scan"
  handler    = "index.handler"
  runtime    = "nodejs24.x"
  iam_policy_arns = [
    var.publish_alerts_policy,
    aws_iam_policy.maintenance_ecs_scan_lambda.arn,
  ]
  error_topics = [var.sns_topic_arn]

  environment = {
    variables = {
      ERROR_TOPIC_ARN      = var.sns_topic_arn
      ALERT_SEVERITY_LEVEL = "CRITICAL"
      IGNORE_SPECS         = var.image_scan_ignore_arn
      SNOOZED_CLUSTERS     = var.image_scan_snooze_arn
      AWS_ACCOUNT_ID       = var.account_id
    }
  }
  tags = {
    "Name" = local.lambda_name
  }
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
    effect = "Allow"
    actions = [
      "ecs:ListClusters"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:StartImageScan",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages"
    ]
    resources = local.ecr_repository_arns
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      var.image_scan_ignore_arn,
      var.image_scan_snooze_arn
    ]
  }
}

resource "aws_iam_policy" "maintenance_ecs_scan_lambda" {
  name   = "maintenance-ecs-scan-lambda"
  policy = data.aws_iam_policy_document.maintenance_ecs_scan_lambda.json
}
