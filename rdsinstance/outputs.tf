// Root username for the database.
output "username" {
  value = try(aws_db_instance.default[0].username, null)
}

// DB Subnet Group Name
output "db_subnet_group_name" {
  value = try(aws_db_subnet_group.subnet_group[0].name, aws_db_subnet_group.default.name)
}

// Root password for the database.
output "password" {
  value = try(aws_db_instance.default[0].password, null)
}

// Hostname for external connection.
output "host" {
  value = try(aws_db_instance.default[0].address, null)
}

// Port for external connection.
output "port" {
  value = try(aws_db_instance.default[0].port, null)
}

// RDS Instance ID.
output "rds_instance_id" {
  # NOTE: You probably want `rds_instance_identifier` instead, as this changed
  # in version 5 of the aws provider.
  value = try(aws_db_instance.default[0].id, null)
}

// ARN of the RDS instance.
output "rds_instance_arn" {
  value = try(aws_db_instance.default[0].arn, aws_rds_cluster_instance.cluster_instances[0].arn)
}

// RDS Resource ID
output "rds_resource_id" {
  value = try(aws_db_instance.default[0].resource_id, null)
}

// Security group that is allowed to access the database.
output "accessor_security_group" {
  value = aws_security_group.db_accessor.id
}
output "db_security_group" {
  value = aws_security_group.db.id
}

output "rds_instance_identifier" {
  value = try(aws_db_instance.default[0].identifier, null)
}

output "master_password_secret_arn" {
  value = var.manage_master_user_password ? try(
    aws_db_instance.default[0].master_user_secret[0].secret_arn, null
  ) : null
}

output "writer_endpoint" {
  value = var.rds_instance_cluster == "instance" ? try(aws_db_instance.default[0].endpoint, null) : try([for instance in aws_rds_cluster_instance.cluster_instances : instance if instance.writer][0], null)
}
output "reader_endpoint" {
  value = var.rds_instance_cluster == "instance" ? try(aws_db_instance.default[0].endpoint, null) : try([for instance in aws_rds_cluster_instance.cluster_instances : instance if !instance.writer][0], null)
}
output "rds_cluster_endpoint" {
  value = try(aws_rds_cluster.default[0].endpoint, null)
}
