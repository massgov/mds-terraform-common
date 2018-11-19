resource "aws_launch_template" "default" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix            = "${var.name}"
  image_id               = "${var.ami}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${var.security_groups}"]
  key_name               = "${var.keypair}"
  user_data              = "${var.user_data}"

  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    arn = "${aws_iam_instance_profile.instance.arn}"
  }

  tag_specifications {
    resource_type = "instance"

    tags = "${merge(var.tags, map(
      "schedulev2", "${var.instance_schedule}",
      "Patch Group", "${var.instance_patch_group}",
      "backup", "${var.instance_backup}"
    ))}"
  }

  tag_specifications {
    resource_type = "volume"

    tags = "${merge(var.tags, map(
      "schedulev2", "${var.instance_schedule}",
      "Patch Group", "${var.instance_patch_group}",
      "backup", "${var.instance_backup}"
    ))}"
  }
}

resource "aws_autoscaling_group" "default" {
  lifecycle {
    create_before_destroy = true
  }

  name                = "${var.name}"
  max_size            = 10
  min_size            = 1
  desired_capacity    = "${var.capacity}"
  vpc_zone_identifier = ["${var.subnets}"]

  launch_template {
    id      = "${aws_launch_template.default.id}"
    version = "$$Latest"
  }

  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "${var.name}"
  }
}
