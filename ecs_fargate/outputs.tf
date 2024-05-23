output "ecs_task_def" {
  value = aws_ecs_task_definition.main
}

output "target_group" {
  value = aws_lb_target_group.alb
}