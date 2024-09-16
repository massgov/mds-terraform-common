locals {
  ecr_repository_names = flatten(values(var.scan_ecr_repositories))
  ecr_repository_arns = formatlist(
    "arn:aws:ecr:${local.region}:${local.account_id}:repository/%s",
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
      "arn:aws:ecs:${local.region}:${local.account_id}:cluster/%s",
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
      region           = local.region
      account_id       = local.account_id
      alerts_topic_arn = aws_sns_topic.maintenance_notifications.arn
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
  service_role_arn = aws_iam_role.maintenance.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "ClusterArn"
        values = [each.value]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.maintenance.arn]
      }
    }
  }
}

// TODO: This can be removed after we switch the calendar to use the lambda.
data "aws_iam_policy_document" "ecr_image_scan" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:StartImageScan", "ecr:DescribeImageScanFindings"]
    resources = local.ecr_repository_arns
  }
}

resource "aws_iam_policy" "ecr_image_scan" {
  name   = "ecr-image-scan"
  policy = data.aws_iam_policy_document.ecr_image_scan.json
}

resource "aws_iam_role_policy_attachment" "ecr_image_scan" {
  role       = aws_iam_role.maintenance.id
  policy_arn = aws_iam_policy.ecr_image_scan.arn
}
