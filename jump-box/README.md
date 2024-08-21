<!-- Most of this file is auto-generated. Only edit the parts before the "BEGIN_TF_DOCS" or after "END_TF_DOCS". -->

# SOE Jump Box Module

This module creates a jump box that allows using Session Manager to connect to private instances. Using SSM means the jump box does not need to be connected to the public internet.

![Jump Box Architecture](./docs/Jump-Box.png)

### Example

```terraform
# Look up latest al2023 ami
data "aws_ami" "default_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

module "vpc" {
  source = "git@github.com:massgov-eotss/soe-v2-modules//vpc?ref=v0.3.0"
  # ...
}

module "jump" {
  source = "git@github.com:massgov-eotss/soe-v2-modules//jump-box?ref=v0.3.0"
  vpc_id = modules.vpc.vpc_id
  subnet_id = modules.vpc.private_subnet_ids[0]
  ami = data.aws_ami.jump.id
  name = "EXAMPLE-JUMP"
}

resource "aws_security_group" "db" {
  name   = "EXAMPLE"
  vpc_id = var.vpc

  # ... other ingress/egress rules

  # Allow ingress from jump box security group on port 5432
  ingress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [module.jump.jump_box_security_group]
  }
}

resource "aws_db_instance" "default" {
  name = "EXAMPLE_DB_NAME"
  vpc_security_group_ids = [aws_security_group.db.id]
  # ...
}

```

### Start session

```bash
#!/usr/bin/env bash

JUMP_INSTANCE=$(aws ec2 describe-instances --filters Name=tag:Name,Values="EXAMPLE-JUMP" Name=instance-state-name,Values=running --query "Reservations[0].Instances[0].InstanceId" --output text)

aws ssm start-session \
    --target $JUMP_INSTANCE

```

### Port forwarding to remote db

```bash
#!/usr/bin/env bash

JUMP_INSTANCE=$(aws ec2 describe-instances --filters Name=tag:Name,Values="EXAMPLE-JUMP" Name=instance-state-name,Values=running --query "Reservations[0].Instances[0].InstanceId" --output text)
DB_HOST=$(aws rds describe-db-instances --db-instance-identifier "EXAMPLE_DBNAME" --query "DBInstances[0].Endpoint.Address" --output text)

aws ssm start-session \
    --target $JUMP_INSTANCE
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$DB_HOST\"],\"portNumber\":[\"5432\"], \"localPortNumber\":[\"5432\"]}"

```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version |
| ------------------------------------------------------------------------ | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.8  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.45 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 5.45 |

## Modules

No modules.

## Resources

| Name                                                                                                                                                 | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_iam_instance_profile.profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile)                 | resource    |
| [aws_iam_role.jump](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                            | resource    |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)         | resource    |
| [aws_iam_role_policy_attachment.ssm_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                                            | resource    |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                | resource    |
| [aws_iam_policy_document.assume_by_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)          | data source |

## Outputs

| Name                                                                                                     | Description |
| -------------------------------------------------------------------------------------------------------- | ----------- |
| <a name="output_jump_box_instance"></a> [jump_box_instance](#output_jump_box_instance)                   | n/a         |
| <a name="output_jump_box_security_group"></a> [jump_box_security_group](#output_jump_box_security_group) | n/a         |

<!-- END_TF_DOCS -->

## Development

To regenerate the documentation, install [`terraform-docs`](https://terraform-docs.io/) and run `terraform-docs .`

## Credits and Resources

This module is based on the [VPC Secure Access POC by MightyAcornDigital](https://github.com/MightyAcornDigital/vpc-secure-access-poc).
