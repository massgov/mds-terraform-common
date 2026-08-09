locals {
  instances = merge([
    for name, group in var.instance_groups : {
      for index in range(group.count) :
      "${name}-${index + 1}" => {
        group          = name
        instance_class = coalesce(group.instance_class, var.instance_class)
        promotion_tier = group.promotion_tier
      }
    }
  ]...)

  custom_endpoint_groups = toset([for name, group in var.instance_groups : name if group.custom_endpoint])
}

resource "aws_rds_cluster_instance" "default" {
  for_each = local.instances

  identifier         = "${var.name}-${each.key}"
  cluster_identifier = aws_rds_cluster.default.id
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
  instance_class     = each.value.instance_class

  db_subnet_group_name         = aws_db_subnet_group.default.name
  promotion_tier               = each.value.promotion_tier
  publicly_accessible          = false
  preferred_maintenance_window = var.preferred_maintenance_window
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  apply_immediately            = var.apply_immediately
  copy_tags_to_snapshot        = true

  tags = merge(var.tags, {
    Name          = "${var.name}-${each.key}"
    InstanceGroup = each.value.group
  })
}

resource "aws_rds_cluster_endpoint" "default" {
  for_each = local.custom_endpoint_groups

  cluster_identifier          = aws_rds_cluster.default.id
  cluster_endpoint_identifier = "${var.name}-${each.value}"
  custom_endpoint_type        = "READER"

  static_members = [
    for key, instance in local.instances :
    aws_rds_cluster_instance.default[key].identifier if instance.group == each.value
  ]

  tags = merge(var.tags, {
    Name = "${var.name}-${each.value}"
  })
}
