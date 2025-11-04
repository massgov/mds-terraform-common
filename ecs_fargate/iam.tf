data "aws_iam_policy_document" "assume_role" {
  count = var.ecs_task_def != null ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "ecs_events_run_task_with_any_role" {
  count = var.ecs_task_def != null ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [replace(aws_ecs_task_definition.main[0].arn, "/:\\d+$/", ":*")]
  }
}
resource "aws_iam_role" "ecs_schedule_role" {
  count              = var.ecs_task_only && var.ecs_task_schedule != "" ? 1 : 0
  name               = join("-", [var.ecs_cluster_name, var.ecs_task_name, "schedule", "role"])
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}
resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  count  = var.ecs_task_only && var.ecs_task_schedule != "" ? 1 : 0
  name   = "ecs_events_run_task_with_any_role"
  role   = aws_iam_role.ecs_schedule_role[0].name
  policy = data.aws_iam_policy_document.ecs_events_run_task_with_any_role[0].json
}

// Ff ecs_create_auto_scale_arn == true, create autoscaling role
resource "aws_iam_role" "ecs_task_autoscale_role" {
  count = var.ecs_create_auto_scale_arn ? 1 : 0
  name  = "${var.ecs_cluster_name}-${var.ecs_task_name}-ecs-autoscale-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_policy" "ecs_task_autoscale_policy" {
  count = var.ecs_create_auto_scale_arn ? 1 : 0
  name  = "${var.ecs_cluster_name}-${var.ecs_task_name}-ecs-autoscale-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:GetScalingPolicy",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "application-autoscaling:DeregisterScalableTarget"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarmHistory"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_autoscale_policy_attachment" {
  count      = var.ecs_create_auto_scale_arn ? 1 : 0
  policy_arn = aws_iam_policy.ecs_task_autoscale_policy[0].arn
  role       = aws_iam_role.ecs_task_autoscale_role[0].name
}

