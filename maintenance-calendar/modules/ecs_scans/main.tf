locals {
  ecr_repository_names = flatten(values(var.scan_ecr_repositories))
  ecr_repository_arns = formatlist(
    "arn:aws:ecr:${var.region}:${var.account_id}:repository/%s",
    local.ecr_repository_names
  )
  all_ecr_repository_scans = flatten([
    for project, repositories in var.scan_ecr_repositories : [
      for repository in repositories : {
        project    = project
        repository = repository
      }
    ]
  ])
  ecs_cluster_names = flatten(values(var.scan_ecs_clusters))
  ecs_cluster_arns = {
    for name in local.ecs_cluster_names :
    name => format(
      "arn:aws:ecs:${var.region}:${var.account_id}:cluster/%s",
      name
    )
  }
}

resource "aws_ssm_document" "ssr_scan_ecr_image" {
  name            = "SSR-ScanECRImage"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/scan_ecr_image_document.yml",
    {
      region           = var.region
      account_id       = var.account_id
      alerts_topic_arn = var.sns_topic_arn
      lambda_arn       = module.ecs_cluster_image_scan.function_arn
    }
  )
}

resource "aws_ssm_maintenance_window" "ecr_image_scan" {
  name              = "ecr-image-scans"
  description       = "Scans ECR images"
  schedule          = "cron(0 9 ? * MON-FRI *)" # 9AM on weekdays
  schedule_timezone = "America/New_York"
  duration          = 3
  cutoff            = 1
}

resource "aws_ssm_maintenance_window_task" "ecr_image_scan" {
  for_each = local.ecs_cluster_arns

  name             = "ecs-scan-${each.key}"
  priority         = 1
  task_arn         = aws_ssm_document.ssr_scan_ecr_image.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.ecr_image_scan.id
  service_role_arn = aws_iam_role.ecs_scans_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "ClusterArn"
        values = [each.value]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.ecs_scans_role.arn]
      }
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
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

resource "aws_iam_role" "ecs_scans_role" {
  name               = "SSR-ECS-Scans-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_scans" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:StartAutomationExecution"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:automation-definition/${aws_ssm_document.ssr_scan_ecr_image.name}:$LATEST"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.ecs_cluster_image_scan.function_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_scans_role.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_scans_policy" {
  name   = "SSR-ECS-Scans-Policy"
  policy = data.aws_iam_policy_document.ecs_scans.json
}

resource "aws_iam_role_policy_attachment" "ecs_scans" {
  role       = aws_iam_role.ecs_scans_role.id
  policy_arn = aws_iam_policy.ecs_scans_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_scans_publish_alerts" {
  role       = aws_iam_role.ecs_scans_role.id
  policy_arn = var.publish_alerts_policy
}