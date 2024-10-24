// compile task containers for resource
locals {
  task_containers = [
    for t in var.ecs_task_def.containers :
    {
      name  = t.container_name
      image = t.image_name

      essential    = true
      portMappings = t.port_mappings
      environment : t.environment_vars

      secrets : [
        for s in t.secret_vars :
        { name : s.name, valueFrom : "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${s.valueFrom}" }
      ]
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.main.name
          awslogs-region : data.aws_region.current.name,
          awslogs-stream-prefix : "ecs"
        }
      }
      volumesFrom : []
      mountPoints : []
      cpu : 0
    }
  ]
}

data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
}

// create a task def if custom task def was not supplied
resource "aws_ecs_task_definition" "main" {
  depends_on         = [aws_cloudwatch_log_group.main]
  count              = length(var.ecs_task_def_custom) == 0 ? 1 : 0
  execution_role_arn = var.ecs_task_def.execution_role_arn
  task_role_arn      = var.ecs_task_def.task_role_arn
  cpu                = var.ecs_task_def.cpu
  memory             = var.ecs_task_def.memory
  family             = var.ecs_task_def.family

  container_definitions = jsonencode(local.task_containers)

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags                     = {}

  dynamic "volume" {
    for_each = var.ecs_task_volumes
    content {
      efs_volume_configuration {
        file_system_id     = volume.value.fs_id
        root_directory     = volume.value.host_path
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = volume.value.access_point_id
          iam             = "ENABLED"
        }
      }

      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

}

// create ecs service under cluster
resource "aws_ecs_service" "main" {
  depends_on                        = [aws_ecs_task_definition.main, aws_lb_target_group.alb]
  name                              = var.ecs_service_name
  cluster                           = data.aws_ecs_cluster.main.cluster_name
  task_definition                   = length(var.ecs_task_def_custom) == 0 ? aws_ecs_task_definition.main[0].arn : var.ecs_task_def_custom
  desired_count                     = var.ecs_desire_count
  health_check_grace_period_seconds = 300

  network_configuration {
    security_groups = var.ecs_security_group_ids
    subnets         = var.ecs_subnet_ids
  }
  launch_type = "FARGATE"

  deployment_circuit_breaker {
    enable   = var.ecs_circuit_breaker
    rollback = var.ecs_circuit_breaker
  }

  dynamic "load_balancer" {
    for_each = var.ecs_load_balancers.alb
    content {
      target_group_arn = aws_lb_target_group.alb[load_balancer.key].arn
      container_name   = load_balancer.key
      container_port   = lookup(load_balancer.value, "container_port")
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.ecs_service_name
    },
  )
}

// optional: scaling target for scaling policies
resource "aws_appautoscaling_target" "main" {
  count              = length(var.ecs_auto_scale_arn) == 0 ? 0 : 1
  max_capacity       = var.ecs_max_count
  min_capacity       = var.ecs_min_count
  resource_id        = "service/${data.aws_ecs_cluster.main.cluster_name}/${aws_ecs_service.main[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.ecs_auto_scale_arn
  lifecycle { ignore_changes = [role_arn] }
}

// optional: scale up when memory is over X %
resource "aws_appautoscaling_policy" "memory" {
  count = length(var.ecs_auto_scale_arn) == 0 ? 0 : var.ecs_auto_scale_memory == 0 ? 0 : 1

  name               = "${data.aws_ecs_cluster.main.cluster_name}-${aws_ecs_service.main.name}-mem-autoScalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[count.index].id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.ecs_auto_scale_memory
  }
}

// optional: scale up when cpu is over X %
resource "aws_appautoscaling_policy" "cpu" {
  count = length(var.ecs_auto_scale_arn) == 0 ? 0 : var.ecs_auto_scale_cpu == 0 ? 0 : 1

  name               = "${data.aws_ecs_cluster.main.cluster_name}-${aws_ecs_service.main.name}-cpu-autoScalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[count.index].id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.ecs_auto_scale_cpu
  }
}

// optional: spin service down on a schedule
resource "aws_appautoscaling_scheduled_action" "schedule_down" {
  count              = length(var.ecs_auto_scale_arn) == 0 ? 0 : var.ecs_auto_scale_schedule_down == "0" ? 0 : 1
  name               = "${data.aws_ecs_cluster.main.cluster_name}-${aws_ecs_service.main.name}-schedule-down"
  resource_id        = aws_appautoscaling_target.main[count.index].id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
  schedule           = "cron(${var.ecs_auto_scale_schedule_down})"

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

// optional: spin service up on a schedule
resource "aws_appautoscaling_scheduled_action" "schedule_up" {
  count              = length(var.ecs_auto_scale_arn) == 0 ? 0 : var.ecs_auto_scale_schedule_up == "0" ? 0 : 1
  name               = "${data.aws_ecs_cluster.main.cluster_name}-${aws_ecs_service.main.name}-schedule-down"
  resource_id        = aws_appautoscaling_target.main[count.index].id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
  schedule           = "cron(${var.ecs_auto_scale_schedule_up})"

  scalable_target_action {
    min_capacity = var.ecs_min_count
    max_capacity = var.ecs_max_count
  }
}

resource "aws_sns_topic" "cb" {
  count = var.ecs_circuit_breaker ? 1 : 0
  name  = join("", [var.ecs_service_name, "CB", "Topic"])
  tags = merge(
    var.tags,
    {
      "Name" = join("", [var.ecs_service_name, "CB", "Topic"])
    },
  )
}

// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_service_deployment_events.html
resource "aws_cloudwatch_event_rule" "cb" {
  count = var.ecs_circuit_breaker ? 1 : 0

  name        = join("", [var.ecs_service_name, "CB", "Rule"])
  description = "Capture and alert when Circuit Break is rolling back"

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail-type" : ["ECS Deployment State Change"],
    "resources" : [
      aws_ecs_service.main.id
    ]
    "detail" : {
      "eventName" : ["SERVICE_DEPLOYMENT_FAILED"]
    }
  })
  tags = merge(
    var.tags,
    {
      "Name" = join("", [var.ecs_service_name, "CB", "Rule"])
    },
  )
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.ecs_circuit_breaker ? 1 : 0

  rule      = aws_cloudwatch_event_rule.cb[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.cb[0].arn
}

resource "aws_sns_topic_subscription" "cb_email_targets" {
  count     = length(var.ecs_circuit_breaker_alert_email)
  topic_arn = aws_sns_topic.cb[0].arn
  protocol  = "email"
  endpoint  = var.ecs_circuit_breaker_alert_email[count.index]
}