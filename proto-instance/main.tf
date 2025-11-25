locals {
  region                 = data.aws_region.default.region
  account                = data.aws_caller_identity.default.account_id
  proto_id               = random_uuid.default.result
  instance_role_name     = var.instance_role_name != null ? var.instance_role_name : aws_iam_role.default[0].name
  user_volume_id         = var.user_volume_id != null ? var.user_volume_id : aws_ebs_volume.default[0].id
  device_name            = "/dev/sdf"
  eni_security_group_ids = var.security_group_ids != null ? var.security_group_ids : [aws_security_group.default[0].id]
}

data "aws_region" "default" {}
data "aws_caller_identity" "default" {}
data "aws_default_tags" "default" {}
data "aws_subnet" "default" {
  id = var.subnet_id
}
data "aws_iam_role" "default" {
  name = aws_iam_instance_profile.default.role
}
data "aws_ebs_volume" "default" {
  most_recent = true
  filter {
    name   = "volume-id"
    values = [local.user_volume_id]
  }
}
data "aws_key_pair" "default" {
  count = var.key_name == null ? 0 : 1

  key_name = var.key_name
}
data "aws_security_group" "default" {
  count = length(local.eni_security_group_ids)

  id = local.eni_security_group_ids[count.index]
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

resource "random_uuid" "default" {}

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "cloudinit_config" "default" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "install_ssm_agent.sh"
    content_type = "text/x-shellscript"

    content = templatefile(
      "${path.module}/cloud/templates/install_ssm_agent.sh.tftpl",
      {}
    )
  }

  part {
    filename     = "mount_user_volume.sh"
    content_type = "text/x-shellscript"

    content = file(
      "${path.module}/cloud/mount_user_volume.sh",
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
  instance_type = var.instance_type
  user_data     = data.cloudinit_config.default.rendered

  # These need to be false so that the management Lambda can interact with the instance
  # via the API
  disable_api_stop        = false
  disable_api_termination = false

  ebs_optimized = true

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
    security_groups             = local.eni_security_group_ids
    delete_on_termination       = false
  }

  placement {
    availability_zone = data.aws_subnet.default.availability_zone
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        "Name"   = "${var.name_prefix}-instance",
        proto-id = local.proto_id
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
}

resource "aws_ebs_volume" "default" {
  count = var.user_volume_id == null ? 1 : 0

  availability_zone = data.aws_subnet.default.availability_zone
  size              = var.user_volume_size

  type = "io1"
  iops = var.user_volume_iops

  final_snapshot = true
}

data "external" "lambda" {
  program     = ["bash", "build-lambda.sh"]
  working_dir = path.module
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions   = ["ec2:DescribeImages"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["ec2:DescribeInstances"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = ["ssm:SendCommand"]
    effect  = "Allow"
    resources = [
      "arn:aws:ssm:${local.region}::document/AWS-RunShellScript",
    ]
  }
  statement {
    actions = ["ssm:SendCommand"]
    effect  = "Allow"
    resources = [
      "arn:aws:ec2:${local.region}:${local.account}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [local.proto_id]
      variable = "ssm:resourceTag/proto-id"
    }
  }
  statement {
    actions   = ["ssm:GetCommandInvocation"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:DetachVolume",
      "ec2:AttachVolume"
    ]
    resources = [data.aws_ebs_volume.default.arn]
    effect    = "Allow"
  }
  statement {
    actions = [
      "ec2:DetachVolume",
      "ec2:AttachVolume"
    ]
    resources = [
      "arn:aws:ec2:${local.region}:${local.account}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [local.proto_id]
      variable = "aws:ResourceTag/proto-id"
    }
    effect = "Allow"
  }
  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "iam:PassRole",
    ]
    effect = "Allow"
    resources = [
      data.aws_iam_role.default.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
  statement {
    actions = ["ec2:RunInstances"]
    effect  = "Allow"
    resources = concat(
      [
        "arn:aws:ec2:${local.region}::image/*",
        "arn:aws:ec2:${local.region}:${local.account}:network-interface/*",
        data.aws_subnet.default.arn,
        aws_launch_template.default.arn,
      ],
      [for key in data.aws_key_pair.default : key.arn],
      [for sg in data.aws_security_group.default : sg.arn]
    )
  }
  statement {
    actions = [
      "ec2:AssociateIamInstanceProfile",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:ReplaceIamInstanceProfileAssociation"
    ]
    resources = [
      "arn:aws:ec2:${local.region}:${local.account}:instance/*",
    ]
    condition {
      test     = "StringEquals"
      values   = [local.proto_id]
      variable = "aws:ResourceTag/proto-id"
    }
  }
  statement {
    actions = [
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:${local.region}:${local.account}:volume/*",
      "arn:aws:ec2:${local.region}:${local.account}:instance/*",
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "ec2:TerminateInstances",
      "ec2:StopInstances"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:${local.region}:${local.account}:instance/*",
    ]
    condition {
      test     = "StringEquals"
      values   = [local.proto_id]
      variable = "aws:ResourceTag/proto-id"
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda" {
  count = var.management_lambda_schedule_expression == null ? 0 : 1

  name                = "${var.name_prefix}-mgmt-lambda-trigger"
  schedule_expression = var.management_lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.management_lambda_schedule_expression == null ? 0 : 1

  rule = aws_cloudwatch_event_rule.lambda[count.index].name
  arn  = module.lambda.lambda_function_arn
}

module "lambda" {
  source     = "terraform-aws-modules/lambda/aws"
  depends_on = [data.external.lambda]

  timeout       = 15 * 60
  function_name = "${var.name_prefix}-management-lambda"
  description   = "Lambda that manages lifecycle of proto instance"
  memory_size   = 1024

  handler                = "index.handler"
  runtime                = "nodejs22.x"
  local_existing_package = "${path.module}/lambda/.dist/handler/package.zip"
  create_package         = false

  allowed_triggers = length(aws_cloudwatch_event_rule.lambda) < 1 ? {} : {
    EventBridgeScheduler = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.lambda[0].arn
    }
  }

  environment_variables = {
    PROTO_ID           = local.proto_id
    VOLUME_ID          = local.user_volume_id
    LAUNCH_TEMPLATE_ID = aws_launch_template.default.id
    DEVICE_NAME        = local.device_name
    AMI_QUERY_JSON     = jsonencode(var.ami_search_filters)
  }

  publish                       = true
  attach_policy_json            = true
  attach_cloudwatch_logs_policy = true
  policy_json                   = data.aws_iam_policy_document.lambda.json
  create_role                   = true
}

/**
  Resources for creating the proto instance just once. We do this because the Lambda function
  becomes responsible for (re)creating the instance once the terraform has been applied the
  first time

  In order to accomplish this, we create the instance outside of the AWS provider with
  terraform_data blocks which never recreate themselves
**/

resource "terraform_data" "instance" {
  triggers_replace = []
  depends_on       = [
    local.user_volume_id,
    aws_launch_template.default
  ]

  provisioner "local-exec" {
    command = <<EOF
      aws ec2 run-instances \
        --image-id=${data.aws_ami.default.id} \
        --launch-template="LaunchTemplateId=${aws_launch_template.default.id},Version=$Latest" \
        --query="Instances[0].InstanceId"
    EOF 
  }
}

resource "time_sleep" "wait" {
  depends_on = [terraform_data.instance]

  create_duration = "30s"
}

data "aws_instances" "instance" {
  depends_on = [terraform_data.instance]

  instance_tags = {
    proto-id = local.proto_id
  }
  instance_state_names = ["running", "pending"]
}

resource "terraform_data" "instance_ok" {
  triggers_replace = []

  provisioner "local-exec" {
    command = "aws ec2 wait instance-running --instance-ids=${one(data.aws_instances.instance.ids)}"
  }
}

resource "terraform_data" "volume_attachment" {
  triggers_replace = []
  depends_on       = [terraform_data.instance_ok]

  provisioner "local-exec" {
    command = <<EOF
      aws ec2 attach-volume \
        --instance-id=${one(data.aws_instances.instance.ids)} \
        --volume-id=${local.user_volume_id} \
        --device=${local.device_name}
    EOF 
  }
}
