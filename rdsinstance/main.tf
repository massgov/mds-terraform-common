data "aws_region" "default" {}
data "aws_caller_identity" "default" {}

resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet"
  subnet_ids = var.subnets
}


// db instance
resource "aws_db_instance" "default" {
  count                                 = var.rds_instance_cluster == "instance" ? 1 : 0
  identifier                            = var.name
  allocated_storage                     = var.allocated_storage
  max_allocated_storage                 = var.max_allocated_storage
  storage_type                          = "gp2"
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  username                              = var.username
  password                              = var.password
  backup_retention_period               = var.backup_retention_period
  backup_window                         = "05:10-06:00"
  copy_tags_to_snapshot                 = true
  deletion_protection                   = var.deletion_protection
  maintenance_window                    = "wed:04:00-wed:05:00"
  storage_encrypted                     = var.storage_encrypted
  parameter_group_name                  = var.parameter_group_name
  db_subnet_group_name                  = aws_db_subnet_group.default.name
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  apply_immediately                     = var.apply_immediately
  iam_database_authentication_enabled   = var.iam_database_authentication_enabled
  ca_cert_identifier                    = var.ca_cert_identifier
  manage_master_user_password           = var.manage_master_user_password
  master_user_secret_kms_key_id         = var.master_user_secret_kms_key_id

  vpc_security_group_ids = flatten([
    var.security_groups,
    aws_security_group.db.id,
  ])
  tags = merge(
    var.tags,
    {
      "Name"        = var.name
      "Patch Group" = var.instance_patch_group
      "schedulev2"  = var.instance_schedule
      "backup"      = var.instance_backup
    },
  )

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  snapshot_identifier = var.snapshot_identifier

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

// db security group
resource "aws_security_group" "db" {
  name   = var.name
  vpc_id = var.vpc
  ingress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.db_accessor.id]
  }
  ingress {
    from_port       = 3600
    protocol        = "tcp"
    to_port         = 3600
    security_groups = [aws_security_group.db_accessor.id]
  }
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

// db accessor security group
resource "aws_security_group" "db_accessor" {
  name   = "${var.name}-accessor"
  vpc_id = var.vpc
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-accessor"
    },
  )
}

// db outgoing
resource "aws_security_group_rule" "accessor_egress_to_db_postgres" {
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "egress"
  security_group_id        = aws_security_group.db_accessor.id
  source_security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "accessor_egress_to_db_mysql" {
  from_port                = 3600
  protocol                 = "tcp"
  to_port                  = 3600
  type                     = "egress"
  security_group_id        = aws_security_group.db_accessor.id
  source_security_group_id = aws_security_group.db.id
}

data "aws_iam_policy_document" "rds_snapshot_create" {
  count = var.enable_manual_snapshots ? 1 : 0
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:rds:${data.aws_region.default.region}:${data.aws_caller_identity.default.account_id}:snapshot:*",
      try(aws_db_instance.default[0].arn, aws_rds_cluster_instance.cluster_instances[0].arn)
    ]
    actions = ["rds:CreateDBSnapshot"]
  }
}

data "aws_iam_policy_document" "rds_snapshot_delete" {
  count = var.enable_manual_snapshots ? 1 : 0
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:rds:${data.aws_region.default.region}:${data.aws_caller_identity.default.account_id}:snapshot:*",
      try(aws_db_instance.default[0].arn, aws_rds_cluster_instance.cluster_instances[0].arn)
    ]
    actions = [
      "rds:DescribeDBSnapshots",
    ]
  }
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:rds:${data.aws_region.default.region}:${data.aws_caller_identity.default.account_id}:snapshot:${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}*"
    ]
    actions = [
      "rds:DeleteDBSnapshot"
    ]
  }
}

module "backup_lambda" {
  count   = var.enable_manual_snapshots ? 1 : 0
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.123"
  name    = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}-backup-lambda"
  package = "${path.module}/dist/backup_lambda.zip"
  handler = "index.handler"
  runtime = "nodejs24.x"
  timeout = 300
  iam_policies = [
    data.aws_iam_policy_document.rds_snapshot_create[count.index].json
  ]
  environment = {
    variables = {
      "RDS_INSTANCE_IDENTIFIER" = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}"
    }
  }
  schedule = var.manual_snapshot_schedule
  tags = merge(
    var.tags,
    {
      "Name" = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}-backup-lambda"
    }
  )
  error_topics = var.backup_error_topics
}

module "cleanup_lambda" {
  count   = var.enable_manual_snapshots ? 1 : 0
  source  = "github.com/massgov/mds-terraform-common//lambda?ref=1.0.123"
  name    = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}-cleanup-lambda"
  package = "${path.module}/dist/cleanup_lambda.zip"
  handler = "index.handler"
  runtime = "nodejs24.x"
  timeout = 300
  iam_policies = [
    data.aws_iam_policy_document.rds_snapshot_delete[count.index].json
  ]
  environment = {
    variables = {
      "RDS_INSTANCE_IDENTIFIER" = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}"
    }
  }
  schedule = {
    first_monday_of_month = "cron(0 23 ? * 2#1 *)"
  }
  tags = merge(
    var.tags,
    {
      "Name" = "${try(aws_db_instance.default[0].identifier, aws_rds_cluster_instance.cluster_instances[0].identifier)}-cleanup-lambda"
    }
  )
  error_topics = var.backup_error_topics
}



resource "aws_rds_cluster" "default" {
  count                               = var.rds_instance_cluster == "cluster" ? 1 : 0
  cluster_identifier                  = "${var.name}-cluster"
  engine                              = var.engine
  engine_version                      = var.engine_version
  database_name                       = var.database_name
  master_username                     = var.username
  master_password                     = var.password
  manage_master_user_password         = var.manage_master_user_password
  master_user_secret_kms_key_id       = var.master_user_secret_kms_key_id
  backup_retention_period             = var.backup_retention_period
  deletion_protection                 = var.deletion_protection
  preferred_maintenance_window        = "wed:04:00-wed:05:00" # 11:00PM-12:00AM EST
  apply_immediately                   = var.apply_immediately
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  storage_encrypted                   = var.storage_encrypted

  preferred_backup_window = "05:10-06:00" # 12:10AM-1:00AM EST
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids = flatten([
    var.security_groups,
    aws_security_group.db.id,
  ])
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-cluster"
    },
  )
}
resource "aws_rds_cluster_instance" "cluster_instances" {
  count                                 = var.rds_instance_cluster == "cluster" ? var.rds_instance_count : 0
  cluster_identifier                    = aws_rds_cluster.default[0].id
  identifier                            = var.name
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  copy_tags_to_snapshot                 = true
  db_parameter_group_name               = var.parameter_group_name
  db_subnet_group_name                  = aws_db_subnet_group.default.name
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  apply_immediately                     = var.apply_immediately
  ca_cert_identifier                    = var.ca_cert_identifier
  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
  lifecycle {
    prevent_destroy = var.deletion_protection
  }

}