
resource "aws_db_subnet_group" "default" {
  name = "${var.name}-subnet"
  subnet_ids = ["${var.subnets}"]
}

// db instance
resource "aws_db_instance" "default" {
  identifier = "${var.name}"
  allocated_storage    = "${var.allocated_storage}"
  storage_type         = "gp2"
  engine               = "${var.engine}"
  engine_version       = "${var.engine_version}"
  instance_class       = "${var.instance_class}"
  username             = "${var.username}"
  password             = "${var.password}"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  vpc_security_group_ids = [
    "${var.security_groups}",
  ]
  tags = "${merge(var.tags, map(
      "Name", "${var.name}",
      "Patch Group", "${var.instance_patch_group}",
      "schedulev2", "${var.instance_schedule}",
      "backup", "${var.instance_backup}"
  ))}"
}
