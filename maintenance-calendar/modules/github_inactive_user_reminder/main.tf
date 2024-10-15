resource "aws_ssm_document" "remind_github_inactive_users" {
  name            = "SSR-RemindGitHubInactiveUsers"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/remind_github_inactive_users.yml",
    {
      region           = var.region
      alerts_topic_arn = var.sns_topic_arn
    }
  )
}

resource "aws_ssm_maintenance_window" "remind_github_inactive_users" {
  name              = "remind_github_inactive_users"
  description       = "Sends a reminder to check and clear inactive GitHub users"
  schedule          = "cron(0 11 ? */3 MON#1)" # First monday of every 3rd month
  schedule_timezone = "America/New_York"
  duration          = 2
  cutoff            = 1
}

resource "aws_ssm_maintenance_window_task" "remind_github_inactive_users" {
  name             = "remind_github_inactive_users"
  task_arn         = aws_ssm_document.remind_github_inactive_users.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.remind_github_inactive_users.id
  service_role_arn = aws_iam_role.github_soe_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.github_soe_role.arn]
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

resource "aws_iam_role" "github_soe_role" {
  name               = "SSR-GitHub-SOE-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "github_soe_policy" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:automation-definition/${aws_ssm_document.remind_github_inactive_users.name}:$LATEST"
    ]
    actions = [
      "ssm:StartAutomationExecution"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.github_soe_role.arn
    ]
  }
}

resource "aws_iam_policy" "github_soe_policy" {
  name   = "SSR-GitHub-SOE-Policy"
  policy = data.aws_iam_policy_document.github_soe_policy.json
}

resource "aws_iam_role_policy_attachment" "github_soe_policy" {
  role       = aws_iam_role.github_soe_role.id
  policy_arn = aws_iam_policy.github_soe_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_soe_publish_alerts" {
  role       = aws_iam_role.github_soe_role.id
  policy_arn = var.publish_alerts_policy
}
