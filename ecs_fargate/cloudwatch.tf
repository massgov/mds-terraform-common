locals {
  log_groups = var.ecs_task_def != null ? {
    for k, v in var.ecs_task_def.containers : v.container_name => v.log_group_name
    if try(v.log_group_name, null) != null
  } : {}
}

output "log_groups" {
  value = local.log_groups
}
resource "aws_cloudwatch_log_group" "main" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cw_kms_key
  tags = merge(
    var.tags,
    {
      "Name" = each.value
    },
  )
}