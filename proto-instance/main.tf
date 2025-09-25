locals {
  user_mount_device_name = "/dev/sdf"
  region                 = data.aws_region.default.region
  instance_role_name     = var.instance_role_name != null ? var.instance_role_name : aws_iam_role.default[0].name
  vpc_security_group_ids = var.security_group_ids != null ? var.security_group_ids : [aws_security_group.default[0].id]
}

data "aws_region" "default" {}
data "aws_default_tags" "default" {}
data "aws_subnet" "default" {
  id = var.subnet_id
}

data "aws_ami" "default" {
  most_recent = true
  owners      = ["self", "amazon"]

  dynamic "filter" {
    for_each = var.ami_search_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.name_prefix}-instance-profile"
  role = local.instance_role_name
}

resource "aws_iam_role" "default" {
  count = var.instance_role_name == null ? 1 : 0

  name = "${var.name_prefix}-instance-profile-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "default" {
  count = var.instance_role_name == null ? 1 : 0

  role       = aws_iam_role.default[count.index].id
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

data "cloudinit_config" "default" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "install_ssm_agent.sh"
    content_type = "text/x-shellscript"

    content = templatefile(
      "${path.module}/templates/install_ssm_agent.sh",
      {
        device_name = local.user_mount_device_name
      }
    )
  }

  part {
    filename     = "mount_user_volume.sh"
    content_type = "text/x-shellscript"

    content = templatefile(
      "${path.module}/templates/mount_user_volume.sh",
      {
        device_name = local.user_mount_device_name
      }
    )
  }

  dynamic "part" {
    for_each = var.additional_clountinit_config_parts
    content {
      filename     = part.value.filename
      content_type = part.value.content_type
      content      = part.value.content
    }
  }
}

resource "aws_security_group" "default" {
  count = var.security_group_ids == null ? 1 : 0

  vpc_id = data.aws_subnet.default.vpc_id
}

resource "aws_security_group_rule" "default" {
  count = var.security_group_ids == null ? 1 : 0

  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.default[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "default" {
  name          = "${var.name_prefix}-launch-template"
  image_id      = data.aws_ami.default.image_id
  instance_type = var.instance_type
  user_data     = data.cloudinit_config.default.rendered

  # These need to be false so that the management Lambda can interact with the instance
  # via the API
  disable_api_stop        = false
  disable_api_termination = false

  ebs_optimized = true
  block_device_mappings {
    device_name = local.user_mount_device_name

    ebs {
      encrypted   = true
      volume_size = var.user_volume_size
    }
  }

  cpu_options {
    core_count       = var.cpu_options.core_count
    threads_per_core = var.cpu_options.threads_per_core
  }
  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.default.arn
  }

  key_name = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = var.subnet_id
    security_groups             = local.vpc_security_group_ids
    delete_on_termination       = false
  }

  placement {
    availability_zone = data.aws_subnet.default.availability_zone
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        "Name" = "${var.name_prefix}-instance"
      },
      data.aws_default_tags.default.tags,
      coalesce(var.tag_specifications["instance"], {})
    )
  }

  dynamic "tag_specifications" {
    for_each = { for k, v in var.tag_specifications : k => v if k != "instance" }
    iterator = spec

    content {
      resource_type = spec.key
      tags = merge(
        data.aws_default_tags.default.tags,
        coalesce(spec.value, {})
      )
    }
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "aws_instance" "default" {
  launch_template {
    id      = aws_launch_template.default.id
    version = "$Latest"
  }
}
