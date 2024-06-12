locals {
  log_groups = var.ecs_task_def != null ? {
    for k, v in var.ecs_task_def.containers : "${v.container_name}" => v
    if try(v.log_group_name, null) == null

  } : {}
}

output "log_groups" {
  value = local.log_groups
}
resource "aws_cloudwatch_log_group" "main" {
  for_each = local.log_groups

  name              = join("/", ["ecs", terraform.workspace, var.ecs_cluster_name, var.ecs_service_name, lookup(each.value, "container_name")])
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cw_kms_key
  tags = merge(
    var.tags,
    {
      "Name" = join("/", ["ecs", terraform.workspace, var.ecs_cluster_name, var.ecs_service_name, lookup(each.value, "container_name")])
    },
  )
}