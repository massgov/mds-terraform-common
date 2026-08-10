resource "aws_security_group" "cluster" {
  name_prefix = "${var.name}-"
  description = "Aurora PostgreSQL cluster ${var.name}."
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_security_group" "accessor" {
  name_prefix = "${var.name}-accessor-"
  description = "Grants access to the Aurora PostgreSQL cluster ${var.name}."
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name}-accessor"
  })
}

resource "aws_vpc_security_group_ingress_rule" "accessor_to_cluster" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.accessor.id
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  description                  = "PostgreSQL from accessors."
}

resource "aws_vpc_security_group_egress_rule" "accessor_to_cluster" {
  security_group_id            = aws_security_group.accessor.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  description                  = "PostgreSQL to ${var.name}."
}
