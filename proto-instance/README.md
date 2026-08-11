# Overview

This module manages the resources for an EC2 instance intended for use during development or prototyping, hence the abbreviated name: _proto_ instance. In order to keep the instance up-to-date with the latest OS builds, the module imposes a level of instance ephemerality. For example, when `var.ami_search_filters` yields a later image than the one currently in use, terraform will tear down and rebuild the EC2 instance. In order to cope with this, the module provisions, mounts, and symlinks a persistent [S3 Filesystem](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files.html) for each user.

## Setup

See [Requirements](#requirements) for a list of required provider versions, as well a the minimum terraform version. If you're using [tfenv](https://github.com/tfutils/tfenv), all of this should be handled for you behind-the-scenes, or almost so.

## Usage

```hcl

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      foo = "bar"
    }
  }
}

data "aws_subnet" "default" {
  id   = "subnet-0aaaaaaaaaaaaaaaa"
}

data "aws_ec2_managed_prefix_list" "default" {
  name = "developer-home-ips"
}

resource "aws_security_group" "default" {
  vpc_id = data.aws_subnet.default.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.default.id
  prefix_list_ids = [
    data.aws_prefix_list.default.id
  ]
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.default.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "proto_instance" {
  source      = "github.com/massgov/mds-terraform-common//proto-instance?ref=1.x"
  subnet_id   = data.aws_subnet.default.id
  name_prefix = "my-cool-instance"
  key_name    = "admin-key-pair"
  security_group_ids = [
    aws_security_group.default.id
  ]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | 2.3.7 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.3.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.7.2 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.13.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.3.7 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.access_s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.mount_s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_alias.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_s3_bucket.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3files_file_system.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3files_file_system) | resource |
| [aws_s3files_mount_target.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3files_mount_target) | resource |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_volume_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_vpc_security_group_ingress_rule.s3fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_uuid.default](https://registry.terraform.io/providers/hashicorp/random/3.7.2/docs/resources/uuid) | resource |
| [aws_ami.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_key_pair.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/key_pair) | data source |
| [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [cloudinit_config.default](https://registry.terraform.io/providers/hashicorp/cloudinit/2.3.7/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_clountinit_config_parts"></a> [additional\_clountinit\_config\_parts](#input\_additional\_clountinit\_config\_parts) | Cloudinit configuration files to include in user data. See https://cloudinit.readthedocs.io/en/latest/explanation/format.html" | <pre>list(object({<br/>    filename     = string<br/>    content_type = string<br/>    content      = string<br/>  }))</pre> | `[]` | no |
| <a name="input_additional_instance_profile_policy_arns"></a> [additional\_instance\_profile\_policy\_arns](#input\_additional\_instance\_profile\_policy\_arns) | ARNs of IAM policies to attach to instance profile | `list(string)` | `[]` | no |
| <a name="input_ami_search_filters"></a> [ami\_search\_filters](#input\_ami\_search\_filters) | List of filters to be applied to AMI search. Note that changing the OS distribution may have unintended consequences, as user data scripts have only been tested in RHEL 10.x. | <pre>list(object({<br/>    name   = string<br/>    values = list(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "name",<br/>    "values": [<br/>      "RHEL-10.*"<br/>    ]<br/>  },<br/>  {<br/>    "name": "architecture",<br/>    "values": [<br/>      "x86_64"<br/>    ]<br/>  }<br/>]</pre> | no |
| <a name="input_attach_volume_ids"></a> [attach\_volume\_ids](#input\_attach\_volume\_ids) | List of IDs of EBS volumes to attach to instance. | `list(string)` | `[]` | no |
| <a name="input_cpu_options"></a> [cpu\_options](#input\_cpu\_options) | CPU options to pass to instance template.<br/>    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html | <pre>object({<br/>    core_count       = number<br/>    threads_per_core = number<br/>  })</pre> | <pre>{<br/>  "core_count": 1,<br/>  "threads_per_core": 2<br/>}</pre> | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type.<br/>    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html | `string` | `"m4.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of SSH key pair installed on instance | `string` | `null` | no |
| <a name="input_management_lambda_schedule_expression"></a> [management\_lambda\_schedule\_expression](#input\_management\_lambda\_schedule\_expression) | Schedule expression to pass to EventBridge Scheduler for management Lambda invocation. If null, the Lambda will not be scheduled to automatically run.<br/>    See https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html for more information | `string` | `"rate(14 days)"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Substring used to prefix resources created by this module | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs to attach to the instance. If no list is provided, a bespoke Security Group will automatically be created with all egress permitted and no ingress permitted. | `list(string)` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of subnet where instance should be placed | `string` | n/a | yes |
| <a name="input_tag_specifications"></a> [tag\_specifications](#input\_tag\_specifications) | Tags to be passed to instance launch template, in addition to provider-level default tags, which will automatically be merged in.<br/>    See https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_LaunchTemplateTagSpecificationRequest.html for a list of valid resource types. | `map(map(string))` | <pre>{<br/>  "instance": {<br/>    "Patch Group": "na",<br/>    "backup": "na",<br/>    "os": "rh10",<br/>    "platform": "linux",<br/>    "schedulev2": "na"<br/>  },<br/>  "volume": {}<br/>}</pre> | no |
| <a name="input_user_volume_iops"></a> [user\_volume\_iops](#input\_user\_volume\_iops) | Number input/output operations per second (IOPS) provisioned to user volume | `number` | `1250` | no |
| <a name="input_user_volume_size"></a> [user\_volume\_size](#input\_user\_volume\_size) | Size, in GiB, of the user volume | `number` | `100` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | n/a |
| <a name="output_proto_id"></a> [proto\_id](#output\_proto\_id) | n/a |
<!-- END_TF_DOCS -->