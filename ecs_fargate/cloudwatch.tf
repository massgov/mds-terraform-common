resource "aws_cloudwatch_log_group" "main" {
  for_each = {
    for task, log in var.ecs_task_def.containers : task => log
    if log.log_group_name != null
  }
  name              = "/ecs/${terraform.workspace}/${var.ecs_cluster_name}/${var.ecs_service_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cw_kms_key
  tags = merge(
    var.tags,
    {
      "Name" = var.ecr_name
    },
  )
}