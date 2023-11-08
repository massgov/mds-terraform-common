locals {
  default_devices = [{ device_name = "/dev/xvda",
    delete_on_termination = true,
    encrypted             = var.volume_encryption,
    iops                  = null,
    snapshot_id           = null,
    throughput            = null,
    volume_size           = var.volume_size,
    volume_type           = null
    }
  ]
}

# TODO: Now that we have this module, I think the `exclude_root_device` option
# makes more sense than the user providing device names to include. However,
# we've already deployed the change using the include names to a bunch of
# repos, so I don't think it makes sense to change this module. If we get a
# good chance in the future (like if the golden image volume changes from
# "/dev/sdf", for example), I think we should switch this to just exclude the
# root volume instead.
module "ami_devices" {
  source                      = "../ami-block-device-reader"
  ami                         = var.ami
  device_filter_type          = "include"
  device_names                = var.include_ami_device_names
  force_delete_on_termination = var.ami_volumes_delete_on_termination
}

data "template_file" "instance_init" {
  template = file("${path.module}/src/instance_init.yml")

  vars = {
    cluster_name = aws_ecs_cluster.cluster.name
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.instance_init.rendered}"
  }

  dynamic "part" {
    for_each = var.additional_cloudinit_configs

    content {
      content_type = "text/cloud-config"
      content      = part.value
      filename     = "init_${part.key}.cfg"
      merge_type   = "list(append)+dict(no_replace, recurse_list)+str(append)"
    }
  }
}

module "asg" {
  source        = "../asg"
  name          = var.name
  keypair       = var.keypair
  capacity      = var.capacity
  instance_type = var.instance_type
  ami           = var.ami

  security_groups = var.security_groups

  subnets              = var.subnets
  policies             = concat(["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"], var.policies)
  user_data            = data.template_cloudinit_config.config.rendered
  instance_schedule    = var.instance_schedule
  instance_patch_group = var.instance_patch_group
  instance_backup      = var.instance_backup
  schedule             = var.schedule
  schedule_down        = var.schedule_down
  schedule_up          = var.schedule_up

  block_devices = concat(local.default_devices, module.ami_devices.block_devices)

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_ecs_cluster" "cluster" {
  name = var.name
}

data "aws_iam_policy_document" "developer" {
  // @todo: There's currently no way to allow describing of services on a per-resource level.
  statement {
    effect = "Allow"
    actions = [
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:DescribeClusters",
      "cloudwatch:GetMetricStatistics",
      // Allows scheduled task visibility
      "events:ListRuleNamesByTarget",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:List*",
      "ecs:Describe*",
    ]
    resources = [aws_ecs_cluster.cluster.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:Describe*",
      "ecs:List*",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:Poll",
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      values   = [aws_ecs_cluster.cluster.arn]
      variable = "ecs:cluster"
    }
  }
}
