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

  # Bucket names can be max 63 characters log
  logs_bucket_suffix = "golden-ami-image-builder-logs"
  logs_bucket_prefix = substr(local.account_alias, 0, 63 - length(local.logs_bucket_suffix))

  output_image_prefix = var.name_prefix
}

module "vpcread" {
  source   = "github.com/massgov/mds-terraform-common//vpcread?ref=1.0.88"
  vpc_name = var.vpc_name
}

module "image_builder_logs" {
  source      = "github.com/massgov/mds-terraform-common//private-bucket?ref=1.0.88"
  bucket_name = "${local.logs_bucket_prefix}-${local.logs_bucket_suffix}"
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

data "aws_iam_policy_document" "instance_profile" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.software_distribution_bucket_id}",
      "arn:aws:s3:::${var.software_distribution_bucket_id}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      /* arn:aws:imagebuilder:us-east-1:aws:component/eni-attachment-test-linux/x.x.x description:
      *
      * To perform this test, an IAM policy with the following actions is required:
      * ec2:AttachNetworkInterface, ec2:CreateNetworkInterface, ec2:CreateTags, ec2:DeleteNetworkInterface,
      * ec2:DescribeNetworkInterfaces, ec2:DescribeNetworkInterfaceAttribute, and ec2:DetachNetworkInterface.
      */
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

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${local.output_image_prefix}-instance-profile"
  role = aws_iam_role.instance_profile.name
}

resource "aws_iam_role" "instance_profile" {
  name               = "${local.output_image_prefix}-instance-profile"
  assume_role_policy = data.aws_iam_policy_document.instance_profile_assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
  ]
}

resource "aws_iam_role_policy" "instance_profile" {
  role   = aws_iam_role.instance_profile.name
  policy = data.aws_iam_policy_document.instance_profile.json
}

resource "aws_kms_grant" "instance_profile" {
  key_id            = var.software_distribution_bucket_key_arn
  operations        = ["Decrypt", "DescribeKey"]
  grantee_principal = aws_iam_role.instance_profile.arn
}

resource "aws_security_group" "all_egress" {
  count = var.security_group_ids == null ? 1 : 0

  name        = "${local.output_image_prefix}-image-builder"
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
  name        = "${local.output_image_prefix}-distribution-configuration"
  description = "Distribution Configuration for Amazon-Linux-2-based Golden AMI"

  distribution {
    ami_distribution_configuration {
      ami_tags = var.tags
      name     = "${local.output_image_prefix}-{{ imagebuilder:buildDate }}"
    }
    region = local.region
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "golden_ami" {
  description           = "Infrastructure configuration for Amazon-Linux-2-based golden AMI pipeline"
  instance_profile_name = aws_iam_instance_profile.instance_profile.name
  instance_types        = ["t3.micro"]
  name                  = "${local.output_image_prefix}-infrastructure-configuration"
  security_group_ids = coalesce(
    var.security_group_ids,
    [for sg in aws_security_group.all_egress : sg.id]
  )
  sns_topic_arn                 = var.alerting_sns_topic_arn
  subnet_id                     = module.vpcread.private_subnets[0]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = module.image_builder_logs.bucket_id
    }
  }

  tags = var.tags
}

resource "aws_imagebuilder_component" "download_and_install_cortex_xdr" {
  description = "Simple component which downloads and installs Cortex XDR agent from distribution bucket"
  data = templatefile(
    "${path.module}/templates/download-and-install-cortex-xdr.yaml",
    {
      software_distribution_bucket_id = var.software_distribution_bucket_id
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
      encrypted             = true
      delete_on_termination = false
      volume_size           = 200
      volume_type           = "gp2"
    }
  }

  working_directory = "/tmp"

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
      value = "/tmp"
    }
  }
  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/yum-repository-test-linux/x.x.x"
  }

  name         = "${local.output_image_prefix}-recipe"
  parent_image = "arn:aws:imagebuilder:${local.region}:aws:image/amazon-linux-2-x86/x.x.x"
  version      = "1.0.0"

  tags = var.tags
}

resource "aws_imagebuilder_image_pipeline" "golden_ami" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_ami.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_ami.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_ami.arn
  name                             = "${local.output_image_prefix}-pipeline"

  schedule {
    schedule_expression                = var.pipeline_schedule_expression
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  tags = var.tags
}
