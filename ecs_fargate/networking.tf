data "aws_lb" "alb" {
  count = var.ec2_alb_arn != null ? 1 : 0
  arn = var.ec2_alb_arn
}

data "aws_lb_listener" "selected" {
  count = var.ec2_alb_arn != null ? 1 : 0
  load_balancer_arn = data.aws_lb.alb[0].arn
  port              = coalesce(var.lb_listener_port, 443)
}

resource "aws_lb_target_group" "alb" {
  for_each = length(coalesce( var.ecs_load_balancers, {})) != 0 ? var.ecs_load_balancers : {}

  name                 = substr(join("-", [terraform.workspace, each.key, lookup(each.value, "tls") ? "HTTPS" : "HTTP"]), 0, 32)
  port                 = lookup(each.value, "service_port", lookup(each.value, "container_port"))
  protocol             = lookup(each.value, "tls") ? "HTTPS" : "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = "60"
  health_check {
    protocol            = lookup(each.value, "tls") ? "HTTPS" : "HTTP"
    interval            = 10
    path                = lookup(each.value, "health_check_path", "/")
    timeout             = 5
    unhealthy_threshold = 5
    healthy_threshold   = 5
    matcher             = "200"
  }
  tags = {}
}

resource "aws_lb_listener_rule" "static" {
  depends_on = [aws_lb_target_group.alb]
#   for_each   = var.ecs_load_balancers
  for_each = length(coalesce( var.ecs_load_balancers, {})) != 0 ? var.ecs_load_balancers : {}

  listener_arn = data.aws_lb_listener.selected[0].arn
#   priority     = lookup(each.value, "container_port")
  tags         = {}

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb[each.key].arn
  }

  dynamic "condition" {
    for_each = try(lookup(each.value, "conditions").host_header, null ) != null ? [1] : []

    content {
      host_header {
        values = lookup(each.value, "conditions").host_header
      }
    }
  }

  dynamic "condition" {
    for_each = try(lookup(each.value, "conditions").path_pattern, null ) != null ? [1] : []

    content {
      path_pattern {
        values = lookup(each.value, "conditions").path_pattern
      }
    }
  }

  dynamic "condition" {
    for_each = try(lookup(each.value, "conditions").http_header, null ) != null ? [1] : []
    content {
      http_header {
        values = lookup(each.value, "conditions").http_header.values
        http_header_name = lookup(each.value, "conditions").http_header.http_header_name
      }
    }
  }

  lifecycle { ignore_changes = [action] }
}

