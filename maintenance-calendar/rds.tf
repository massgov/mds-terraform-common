data "aws_db_instances" "dbinstance" {
  filter {
    name   = "db-instance-id"
    values = var.rds_instance_names
  }
}

// Maybe add handling for db clusters too? Otherwise this will silently ignore them

resource "aws_ssm_document" "ssr_create_rds_snapshot" {
  name            = "SSR-CreateRDSSnapshot"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/create_rds_snapshot.yml",
    {
      region           = local.region
      alerts_topic_arn = aws_sns_topic.maintenance_notifications.arn
    }
  )
}

resource "aws_ssm_document" "ssr_clean_up_rds_snapshots" {
  name            = "SSR-CleanUpRDSSnapshots"
  document_format = "YAML"
  document_type   = "Automation"
  content = templatefile(
    "${path.module}/templates/clean_up_rds_snapshots.yml",
    {
      region           = local.region
      alerts_topic_arn = aws_sns_topic.maintenance_notifications.arn
    }
  )
}

resource "aws_iam_role" "rds_backups_role" {
  name               = "SSRRDSBackupsRole"
  assume_role_policy = data.aws_iam_policy_document.maintenance_assume_role_policy.json
}

data "aws_iam_policy_document" "rds_backups" {
  statement {
    effect = "Allow"
    resources = formatlist(
      "arn:aws:rds:${local.region}:${local.account_id}:snapshot:%s-*",
      data.aws_db_instances.dbinstance.instance_identifiers
    )
    actions = [
      "rds:AddTagsToResource",
      "rds:DescribeDBSnapshots",
      "rds:DeleteDBSnapshot",
      "rds:CreateDBSnapshot"
    ]
  }
  statement {
    effect    = "Allow"
    resources = data.aws_db_instances.dbinstance.instance_arns
    actions = [
      "rds:CreateDBSnapshot",
      "rds:DescribeDBSnapshots",
      "rds:DescribeDBInstances"
    ]
  }
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:ssm:${local.region}::automation-definition/AWS-CreateRdsSnapshot:$LATEST"
    ]
    actions = [
      "ssm:StartAutomationExecution"
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

resource "aws_iam_policy" "rds_backups_policy" {
  name   = "rds-backups"
  policy = data.aws_iam_policy_document.rds_backups.json
}

resource "aws_iam_role_policy_attachment" "rds_backups" {
  role       = aws_iam_role.rds_backups_role.id
  policy_arn = aws_iam_policy.rds_backups_policy.arn
}

resource "aws_iam_role_policy_attachment" "rds_backups_publish_alerts" {
  role       = aws_iam_role.rds_backups_role.id
  policy_arn = aws_iam_policy.maintenance_publish_alerts.arn
}

resource "aws_iam_role_policy_attachment" "rds_backups_maintenance_logs" {
  role       = aws_iam_role.rds_backups_role.id
  policy_arn = aws_iam_policy.maintenance_publish_alerts.arn
}

resource "aws_ssm_maintenance_window" "rds_backups_window" {
  name              = "rds-backups"
  description       = "Takes snapshots of all RDS instances"
  schedule          = "cron(0 2 ? * MON#1 *)" # 2AM first monday of the month
  schedule_timezone = "America/New_York"
  duration          = 3
  cutoff            = 1
}

resource "aws_ssm_maintenance_window_task" "rds_create_backups" {
  for_each = toset(data.aws_db_instances.dbinstance.instance_identifiers)

  priority         = 1
  name             = "${each.key}-create-backup"
  task_arn         = aws_ssm_document.ssr_create_rds_snapshot.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.rds_backups_window.id
  service_role_arn = aws_iam_role.rds_backups_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "DBInstanceIdentifier"
        values = [each.key]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.rds_backups_role.arn]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "rds_destroy_backups" {
  for_each = toset(data.aws_db_instances.dbinstance.instance_identifiers)

  priority         = 2
  name             = "${each.key}-clean-up-backups"
  task_arn         = aws_ssm_document.ssr_clean_up_rds_snapshots.arn
  task_type        = "AUTOMATION"
  window_id        = aws_ssm_maintenance_window.rds_backups_window.id
  service_role_arn = aws_iam_role.rds_backups_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "DBInstanceIdentifier"
        values = [each.key]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.rds_backups_role.arn]
      }
    }
  }
}