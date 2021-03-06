resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet"
  subnet_ids = var.subnets
}


// db instance
resource "aws_db_instance" "default" {
  identifier                            = var.name
  allocated_storage                     = var.allocated_storage
  storage_type                          = "gp2"
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  username                              = var.username
  password                              = var.password
  backup_retention_period               = var.backup_retention_period
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

