data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

resource "aws_sns_topic" "maintenance_notifications" {
  name         = var.maintenance_sns_topic
  display_name = var.maintenance_sns_display_name
}

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

resource "aws_iam_role_policy_attachment" "maintenance_logs_bucket" {
  role       = aws_iam_role.maintenance.id
  policy_arn = aws_iam_policy.maintenance_logs_bucket.arn
}

data "aws_iam_policy_document" "maintenance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ssm.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "maintenance" {
  name               = "SSRMaintenanceCalendarRole"
  assume_role_policy = data.aws_iam_policy_document.maintenance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "maintenance_window" {
  role       = aws_iam_role.maintenance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

data "aws_iam_policy_document" "maintenance_publish_alerts" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.maintenance_notifications.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:StartAutomationExecution"
    ]
    resources = [
      "arn:aws:ssm:${local.region}::automation-definition/AWS-PublishSNSNotification:$LATEST"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetAutomationExecution"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "maintenance_publish_alerts" {
  name   = "maintenance-publish-alerts"
  policy = data.aws_iam_policy_document.maintenance_publish_alerts.json
}

resource "aws_iam_role_policy_attachment" "maintenance_publish_alerts" {
  role       = aws_iam_role.maintenance.id
  policy_arn = aws_iam_policy.maintenance_publish_alerts.arn
}

data "aws_iam_policy_document" "maintenance_run_automation" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.maintenance.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:ListCommandInvocations",
      "ssm:GetCommandInvocation"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.ecs_cluster_image_scan.function_arn]
  }
}

resource "aws_iam_policy" "maintenance_run_automation" {
  name   = "maintenance-run-automation"
  policy = data.aws_iam_policy_document.maintenance_run_automation.json
}

resource "aws_iam_role_policy_attachment" "maintenance_run_automation" {
  role       = aws_iam_role.maintenance.id
  policy_arn = aws_iam_policy.maintenance_run_automation.arn
}

module "github_inactive_user_reminder" {
  source                = "./modules/github_inactive_user_reminder"
  count                 = var.create_github_inactive_user_reminder ? 1 : 0
  sns_topic_arn         = aws_sns_topic.maintenance_notifications.arn
  publish_alerts_policy = aws_iam_policy.maintenance_publish_alerts.arn
}