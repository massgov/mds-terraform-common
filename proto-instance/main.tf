locals {
  region  = data.aws_region.default.region
  account = data.aws_caller_identity.default.account_id

  eni_security_group_ids = setunion(
    [aws_security_group.default.id],
    coalesce(var.security_group_ids, [])
  )
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
data "aws_key_pair" "default" {
  count = var.key_name == null ? 0 : 1

  key_name = var.key_name
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

################################################################################
# S3 file system resources
################################################################################

resource "aws_kms_key" "s3fs" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMManagement"
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.account}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}
resource "aws_kms_alias" "s3fs" {
  name          = "alias/${var.name_prefix}-s3fs-kms"
  target_key_id = aws_kms_key.s3fs.key_id
}

resource "aws_s3_bucket" "s3fs" {
  bucket = "${var.name_prefix}-s3fs"
  tags = {
    Name = "${var.name_prefix}-s3fs"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3fs" {
  bucket = aws_s3_bucket.s3fs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3fs.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3fs" {
  bucket = aws_s3_bucket.s3fs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "s3fs" {
  name_prefix = "${var.name_prefix}-s3fs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3FilesAssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        },
        Action = ["sts:AssumeRole"]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3files:us-east-1:${local.account}:file-system/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "access_s3fs" {
  name_prefix = "${var.name_prefix}-access-s3fs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketPermissions",
        Effect = "Allow",
        Action = [
          "s3:ListBucket*"
        ],
        Resource = [
          aws_s3_bucket.s3fs.arn
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account
          }
        }
      },
      {
        Sid    = "S3ObjectPermissions",
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*"
        ],
        Resource = [
          "${aws_s3_bucket.s3fs.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account
          }
        }
      },
      {
        Sid    = "UseKmsKeyWithS3Files",
        Effect = "Allow",
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo"
        ],
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${local.region}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : [
              aws_s3_bucket.s3fs.arn,
              "${aws_s3_bucket.s3fs.arn}/*"
            ]
          }
        },
        Resource = [aws_kms_key.s3fs.arn]
      },
      {
        Sid    = "EventBridgeManage",
        Effect = "Allow",
        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ],
        Condition = {
          StringEquals = {
            "events:ManagedBy" = "elasticfilesystem.amazonaws.com"
          }
        },
        Resource = [
          "arn:aws:events:*:*:rule/DO-NOT-DELETE-S3-Files*"
        ]
      },
      {
        Sid    = "EventBridgeRead",
        Effect = "Allow",
        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule"
        ],
        Resource = [
          "arn:aws:events:*:*:rule/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3fs" {
  role       = aws_iam_role.s3fs.id
  policy_arn = aws_iam_policy.access_s3fs.arn
}

resource "aws_security_group" "s3fs" {
  name        = "${var.name_prefix}-s3fs-ingress"
  description = "Allow inbound s3files traffic from ${var.name_prefix}-instance"
  vpc_id      = data.aws_subnet.default.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "s3fs" {
  description                  = "Allow inbound NFS traffic from ${var.name_prefix}-instance"
  security_group_id            = aws_security_group.s3fs.id
  referenced_security_group_id = aws_security_group.default.id
  ip_protocol                  = "tcp"
  from_port                    = "2049"
  to_port                      = "2049"
}

resource "aws_s3files_file_system" "s3fs" {
  bucket     = aws_s3_bucket.s3fs.arn
  role_arn   = aws_iam_role.s3fs.arn
  kms_key_id = aws_kms_key.s3fs.arn
}

resource "aws_s3files_mount_target" "s3fs" {
  file_system_id = aws_s3files_file_system.s3fs.id
  subnet_id      = var.subnet_id
  security_groups = [
    aws_security_group.s3fs.id
  ]
}

################################################################################
# EC2 instance profile resources
################################################################################

resource "aws_iam_instance_profile" "default" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.default.name
}

resource "aws_iam_role" "default" {
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

resource "aws_iam_policy" "mount_s3fs" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MountS3FileSystem"
        Effect = "Allow"
        Action = [
          "s3files:ClientMount",
          "s3files:ClientWrite",
          "s3files:ClientRootAccess"
        ]
        Resource = [
          aws_s3files_file_system.s3fs.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = merge(var.additional_instance_profile_policy_arns, {
    mount_s3fs  = aws_iam_policy.mount_s3fs.arn,
    access_s3fs = aws_iam_policy.access_s3fs.arn
  })

  role       = aws_iam_role.default.id
  policy_arn = each.value
}

################################################################################
# EC2 launch template and instance resources
################################################################################

data "cloudinit_config" "default" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "install_ssm_agent.sh"
    content_type = "text/x-shellscript"

    content = file(
      "${path.module}/cloud/install_ssm_agent.sh",
    )
  }

  part {
    filename     = "mount_s3fs.sh"
    content_type = "text/x-shellscript"

    content = templatefile(
      "${path.module}/cloud/templates/mount_s3fs.sh.tmpl",
      {
        file_system_id = aws_s3files_file_system.s3fs.id
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
  vpc_id = data.aws_subnet.default.vpc_id
}

resource "aws_security_group_rule" "default" {
  count = var.security_group_ids == null ? 1 : 0

  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.default.id
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
        "Name" = "${var.name_prefix}-instance",
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

resource "aws_instance" "default" {
  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }
}

resource "aws_volume_attachment" "default" {
  for_each = var.volume_attachments

  volume_id   = each.key
  device_name = each.value
  instance_id = aws_instance.default.id
}
