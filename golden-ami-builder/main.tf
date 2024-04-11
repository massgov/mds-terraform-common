data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}
data "aws_region" "current" {}

data "aws_kms_key" "volume_key" {
  key_id = var.volume_key_alias
}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  account_alias = data.aws_iam_account_alias.current.account_alias
  region        = data.aws_region.current.name
}

module "golden_ami_lookup" {
  source = "../golden-ami-lookup"
}

module "vpcread" {
  source   = "github.com/massgov/mds-terraform-common//vpcread?ref=1.0.88"
  vpc_name = var.vpc_name
}

module "pipeline_logs" {
  count = var.disable_logging_bucket ? 0 : 1

  source      = "github.com/massgov/mds-terraform-common//private-bucket?ref=1.0.88"
  bucket_name = "${local.account_alias}-${module.golden_ami_lookup.ami_name_prefix}-pipeline-logs"
  tags        = var.tags
}

data "aws_iam_policy_document" "instance_profile_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "instance_profile_read_dist_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.distribution_bucket_id}",
      "arn:aws:s3:::${var.distribution_bucket_id}/*"
    ]
  }
}

data "aws_iam_policy_document" "instance_profile_create_eni" {
  /* arn:aws:imagebuilder:us-east-1:aws:component/eni-attachment-test-linux/x.x.x description:
   *
   * To perform this test, an IAM policy with the following actions is required:
   * ec2:AttachNetworkInterface, ec2:CreateNetworkInterface, ec2:CreateTags, ec2:DeleteNetworkInterface,
   * ec2:DescribeNetworkInterfaces, ec2:DescribeNetworkInterfaceAttribute, and ec2:DetachNetworkInterface.
  */
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateTags",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DetachNetworkInterface"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "instance_profile" {
  name               = module.golden_ami_lookup.ami_name_prefix
  assume_role_policy = data.aws_iam_policy_document.instance_profile_assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
  ]
}

resource "aws_iam_role_policy" "read_dist_bucket" {
  role   = aws_iam_role.instance_profile.name
  policy = data.aws_iam_policy_document.instance_profile_read_dist_bucket.json
}

resource "aws_iam_role_policy" "create_eni" {
  role   = aws_iam_role.instance_profile.name
  policy = data.aws_iam_policy_document.instance_profile_create_eni.json
}

resource "aws_security_group" "all_egress" {
  count = var.security_group_ids == null ? 1 : 0

  name        = "${module.golden_ami_lookup.ami_name_prefix}-image-builder"
  description = "Security group used by Image Builder instances. Allows no inbound traffic and all outbound traffic."
  vpc_id      = module.vpcread.vpc

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_imagebuilder_distribution_configuration" "golden_ami" {
  name        = "${module.golden_ami_lookup.ami_name_prefix}-distribution-configuration"
  description = "Distribution Configuration for Amazon-Linux-2-based Golden AMI"

  distribution {
    ami_distribution_configuration {
      ami_tags = var.tags
      name     = "${module.golden_ami_lookup.ami_name_prefix}-{{ imagebuilder:buildDate }}"
    }
    region = local.region
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "golden_ami" {
  description           = "Infrastructure configuration for Amazon-Linux-2-based golden AMI pipeline"
  instance_profile_name = aws_iam_role.instance_profile.id
  instance_types        = ["t3.micro"]
  name                  = "${module.golden_ami_lookup.ami_name_prefix}-infrastructure-configuration"
  security_group_ids = coalesce(
    var.security_group_ids,
    [for sg in aws_security_group.all_egress : sg.id]
  )
  sns_topic_arn                 = var.alerting_sns_topic_arn
  subnet_id                     = module.vpcread.private_subnets[0]
  terminate_instance_on_failure = true

  dynamic "logging" {
    for_each = var.disable_logging_bucket ? module.pipeline_logs : []
    iterator = "bucket"

    content {
      s3_logs {
        s3_bucket_name = bucket.value["bucket_id"]
      }
    }
  }

  tags = var.tags
}

resource "aws_imagebuilder_component" "download_and_install_cortex_xdr" {
  description = "Simple component which downloads and installs Cortex XDR agent from distribution bucket"
  data = templatefile(
    "${path.module}/templates/download-and-install-cortex-xdr.yaml",
    {
      distribution_bucket_id = var.distribution_bucket_id
    }
  )
  name     = "download-and-install-cortex-xdr"
  platform = "Linux"
  version  = "1.0.0"

  tags = var.tags
}

resource "aws_imagebuilder_image_recipe" "golden_ami" {
  description = "Recipe for Amazon-Linux-2-based Golden AMI"

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      kms_key_id            = data.aws_kms_key.volume_key.arn
      delete_on_termination = false
      volume_size           = 200
      volume_type           = "gp2"
    }
  }

  block_device_mapping {
    device_name = "/dev/sdf"

    ebs {
      kms_key_id            = data.aws_kms_key.volume_key.arn
      delete_on_termination = false
      volume_size           = 250
      volume_type           = "gp2"
    }
  }

  working_directory = "/var/tmp"

  # Build components
  component {
    component_arn = aws_imagebuilder_component.download_and_install_cortex_xdr.arn
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/aws-cli-version-2-linux/x.x.x"
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/update-linux/x.x.x"
  }

  # Test components
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/simple-boot-test-linux/x.x.x"
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/eni-attachment-test-linux/x.x.x"
    parameter {
      name  = "WorkingPath"
      value = "/var/tmp"
    }
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/yum-repository-test-linux/x.x.x"
  }

  name         = "${module.golden_ami_lookup.ami_name_prefix}-recipe"
  parent_image = "arn:aws:imagebuilder:${local.region}:aws:image/amazon-linux-2-x86/x.x.x"
  version      = "1.0.0"

  tags = var.tags
}

resource "aws_imagebuilder_image_pipeline" "golden_ami" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_ami.arn
  infrastructure_configuration_arn = aws_imagebuilder_distribution_configuration.golden_ami.arn
  name                             = "${module.golden_ami_lookup.ami_name_prefix}-pipeline"

  schedule {
    schedule_expression                = "cron(0 2 1 * ? *)" # First day of every month at 2AM eastern
    timezone                           = "America/New_York"
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  tags = var.tags
}
