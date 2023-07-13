# Default AMI to use when none is specified.
data "aws_ssm_parameter" "golden_ami_latest" {
  name = "/GoldenAMI/Linux/AWS2/latest"
}

# Look up AMI for `include_ami_device_names`
data "aws_ami" "default" {
  filter {
    name = "image-id"
    values = [local.ami]
  }
}

locals {
  ami = coalesce(var.ami, data.aws_ssm_parameter.golden_ami_latest.value)

  ami_devices = [
    for mapping in data.aws_ami.default.block_device_mappings :
      # flatten object so there isn't a nested "ebs" object
      merge(
         {device_name = mapping.device_name},
         mapping.ebs,
         # overwrite delete_on_termination based on variable
         var.ami_volumes_delete_on_termination ? { delete_on_termination = true } : {}
      )
      # Only include devices specified in `include_ami_device_names`.
      if contains(var.include_ami_device_names, mapping.device_name)
  ]

  default_devices = [ { device_name = "/dev/xvda",
                        delete_on_termination = true,
                        encrypted = var.volume_encryption,
                        iops = null,
                        snapshot_id = null,
                        throughput = null,
                        volume_size = var.volume_size,
                        volume_type = null
                      }
                    ]
}

module "asg" {
  source        = "../asg"
  name          = var.name
  keypair       = var.keypair
  capacity      = var.capacity
  instance_type = var.instance_type
  ami           = local.ami

  security_groups = var.security_groups

  subnets              = var.subnets
  policies             = concat(["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"], var.policies)
  user_data            = base64encode(data.template_file.instance_init.rendered)
  instance_schedule    = var.instance_schedule
  instance_patch_group = var.instance_patch_group
  instance_backup      = var.instance_backup
  schedule             = var.schedule
  schedule_down        = var.schedule_down
  schedule_up          = var.schedule_up

  block_devices = concat(local.default_devices, local.ami_devices)

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

data "template_file" "instance_init" {
  template = file("${path.module}/src/instance_init.yml")

  vars = {
    cluster_name = aws_ecs_cluster.cluster.name
  }
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
      test = "ArnEquals"
      values = [aws_ecs_cluster.cluster.arn]
      variable = "ecs:cluster"
    }
  }
}
