data "aws_lb" "alb" {
  arn = var.ec2_alb_arn
}

data "aws_lb_listener" "selected_443" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 443
}

resource "aws_lb_target_group" "alb" {
  for_each = var.ecs_load_balancers.alb

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
  for_each   = var.ecs_load_balancers.alb

  listener_arn = data.aws_lb_listener.selected_443.arn
  priority     = lookup(each.value, "container_port")
  tags         = {}

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb[each.key].arn
  }

  condition {

    host_header {
      values = lookup(each.value.conditions, "host_header")
    }

  }

  lifecycle { ignore_changes = [action] }
}

