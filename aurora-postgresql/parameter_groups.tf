resource "aws_rds_cluster_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = local.parameter_group_family
  description = "Aurora PostgreSQL cluster ${var.name}."

  parameter {
    name         = "rds.force_ssl"
    value        = var.force_ssl ? "1" : "0"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
