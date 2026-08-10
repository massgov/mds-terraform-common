output "cluster_identifier" {
  description = "Identifier of the Aurora cluster."
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster."
  value       = aws_rds_cluster.this.arn
}

output "cluster_resource_id" {
  description = "Immutable resource ID of the cluster, used in IAM database authentication policies."
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "writer_endpoint" {
  description = "Endpoint for the current writer instance."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Load balanced endpoint across every reader in the cluster. Use the per-group custom endpoints instead when the cluster has more than one reader group."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Port the cluster listens on."
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Name of the initial database."
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Master username."
  value       = aws_rds_cluster.this.master_username
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the master password."
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}

output "instance_identifiers" {
  description = "Identifiers of the cluster instances, keyed by instance group and ordinal."
  value       = { for key, instance in aws_rds_cluster_instance.this : key => instance.identifier }
}

output "instance_endpoints" {
  description = "Endpoints of the individual cluster instances, keyed by instance group and ordinal."
  value       = { for key, instance in aws_rds_cluster_instance.this : key => instance.endpoint }
}

output "custom_endpoints" {
  description = "Reader endpoints created for instance groups, keyed by group name."
  value       = { for name, endpoint in aws_rds_cluster_endpoint.this : name => endpoint.endpoint }
}

output "security_group_id" {
  description = "Security group attached to the cluster."
  value       = aws_security_group.cluster.id
}

output "accessor_security_group_id" {
  description = "Security group to attach to clients that need to reach the cluster."
  value       = aws_security_group.accessor.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "cluster_parameter_group_name" {
  description = "Name of the cluster parameter group."
  value       = aws_rds_cluster_parameter_group.this.name
}

output "kms_key_arn" {
  description = "ARN of the key encrypting the storage volume and the master password secret. Null when the AWS managed keys are used."
  value       = local.kms_key_arn
}
