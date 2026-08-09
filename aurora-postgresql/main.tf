resource "aws_db_subnet_group" "default" {
  name       = var.name
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_rds_cluster" "default" {
  cluster_identifier = var.name
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version
  storage_type       = var.storage_type
  port               = var.port

  database_name               = var.database_name
  master_username             = var.master_username
  manage_master_user_password = true

  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = concat(
    [aws_security_group.cluster.id],
    var.security_group_ids,
  )

  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  copy_tags_to_snapshot        = true

  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.name}-final")

  tags = merge(var.tags, {
    Name = var.name
  })
}
