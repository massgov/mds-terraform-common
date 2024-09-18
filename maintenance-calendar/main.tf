data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

module "rds_snapshots" {
  source                = "./modules/rds_snapshots"
  count                 = var.create_rds_snapshots ? 1 : 0
  region                = local.region
  account_id            = local.account_id
  sns_topic_arn         = aws_sns_topic.maintenance_notifications.arn
  publish_alerts_policy = aws_iam_policy.maintenance_publish_alerts.arn
  rds_instance_names    = var.rds_instance_names
}

module "ecs_scans" {
  source                = "./modules/ecs_scans"
  count                 = var.create_ecs_scans ? 1 : 0
  region                = local.region
  account_id            = local.account_id
  sns_topic_arn         = aws_sns_topic.maintenance_notifications.arn
  publish_alerts_policy = aws_iam_policy.maintenance_publish_alerts.arn
  scan_ecs_clusters     = var.scan_ecs_clusters
  scan_ecr_repositories = var.scan_ecr_repositories
}

module "github_inactive_user_reminder" {
  source                = "./modules/github_inactive_user_reminder"
  count                 = var.create_github_inactive_user_reminder ? 1 : 0
  region                = local.region
  account_id            = local.account_id
  sns_topic_arn         = aws_sns_topic.maintenance_notifications.arn
  publish_alerts_policy = aws_iam_policy.maintenance_publish_alerts.arn
}

resource "aws_sns_topic" "maintenance_notifications" {
  name         = var.maintenance_sns_topic
  display_name = var.maintenance_sns_display_name
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
    // All the maintenance window tasks need this to get their own status too
    // If for some reason this policy isn't attached they'll fail at runtime
    effect = "Allow"
    actions = [
      "ssm:GetAutomationExecution"
    ]
    resources = [
      "arn:aws:ssm:${local.region}:${local.account_id}:automation-execution/*"
    ]
  }
}

resource "aws_iam_policy" "maintenance_publish_alerts" {
  name   = "SSR-Maintenance-Publish-Alerts-Policy"
  policy = data.aws_iam_policy_document.maintenance_publish_alerts.json
}