// Root username for the database.
output "username" {
  value = aws_db_instance.default.username
}

// Root password for the database.
output "password" {
  value = aws_db_instance.default.password
}

// Hostname for external connection.
output "host" {
  value = aws_db_instance.default.address
}

// Port for external connection.
output "port" {
  value = aws_db_instance.default.port
}

// RDS Instance ID.
output "rds_instance_id" {
  # NOTE: You probably want `rds_instance_identifier` instead, as this changed
  # in version 5 of the aws provider.
  value = aws_db_instance.default.id
}

// ARN of the RDS instance.
output "rds_instance_arn" {
  value = aws_db_instance.default.arn
}

// RDS Resource ID
output "rds_resource_id" {
  value = aws_db_instance.default.resource_id
}

// Security group that is allowed to access the database.
output "accessor_security_group" {
  value = aws_security_group.db_accessor.id
}

output "rds_instance_identifier" {
  value = aws_db_instance.default.identifier
}

output "master_password_secret_arn" {
  value = var.manage_master_user_password ? try(
    aws_db_instance.default.master_user_secret[0].secret_arn, null
  ) : null
}
