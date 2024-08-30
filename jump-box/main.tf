resource "aws_security_group" "this" {
  name   = "${var.name}-jump"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    protocol    = "ALL"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "assume_by_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "jump" {
  assume_role_policy = data.aws_iam_policy_document.assume_by_ec2.json
  name               = "${var.name}-instance"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.jump.id
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.jump.id
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.name}-instance"
  role = aws_iam_role.jump.id
}

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.profile.id
  user_data              = var.user_data

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    "Name" = "${var.name}"
  }
}
