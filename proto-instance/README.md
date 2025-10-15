# Overview

This module manages the resources for an EC2 instance intended for use during development or prototyping, hence the abbreviated name: _proto_ instance. The module differ from, say, the `aws_instance` resource provided by the aws terraform provider in a few ways; chief among them is the inclusion of a _management_ Lambda function, which periodically tears the instance down and rebuilds it using the latest version of the AMI given by [var.ami_search_filters](#ami_search_filters).

## Setup

See [Requirements](#requirements) for a list of required provider versions, as well a the minimum terraform version. If you're using [tfenv](https://github.com/tfutils/tfenv), all of this should be handled for you behind-the-scenes, or almost so.

## Usage

```hcl

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      foo = bar
    }
  }
}

data "aws_subnet" "default" {
  id   = "subnet-0aaaaaaaaaaaaaaaa"
}

data "aws_prefix_list" "default" {
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

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.13)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (>= 6.0)

- <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) (2.3.7)

- <a name="requirement_external"></a> [external](#requirement\_external) (2.3.5)

- <a name="requirement_random"></a> [random](#requirement\_random) (3.7.2)

- <a name="requirement_time"></a> [time](#requirement\_time) (0.13.1)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (>= 6.0)

- <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) (2.3.7)

- <a name="provider_external"></a> [external](#provider\_external) (2.3.5)

- <a name="provider_random"></a> [random](#provider\_random) (3.7.2)

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

- <a name="provider_time"></a> [time](#provider\_time) (0.13.1)

## Modules

The following Modules are called:

### <a name="module_lambda"></a> [lambda](#module\_lambda)

Source: terraform-aws-modules/lambda/aws

Version:

## Resources

The following resources are used by this module:

- [aws_cloudwatch_event_rule.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) (resource)
- [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) (resource)
- [aws_ebs_volume.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) (resource)
- [aws_iam_instance_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) (resource)
- [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_launch_template.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) (resource)
- [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) (resource)
- [aws_security_group_rule.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [random_uuid.default](https://registry.terraform.io/providers/hashicorp/random/3.7.2/docs/resources/uuid) (resource)
- [terraform_data.instance](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [terraform_data.instance_ok](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [terraform_data.volume_attachment](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/0.13.1/docs/resources/sleep) (resource)
- [aws_ami.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) (data source)
- [aws_caller_identity.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_default_tags.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) (data source)
- [aws_ebs_volume.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_volume) (data source)
- [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) (data source)
- [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) (data source)
- [aws_instances.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances) (data source)
- [aws_key_pair.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/key_pair) (data source)
- [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)
- [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) (data source)
- [aws_subnet.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) (data source)
- [cloudinit_config.default](https://registry.terraform.io/providers/hashicorp/cloudinit/2.3.7/docs/data-sources/config) (data source)
- [external_external.lambda](https://registry.terraform.io/providers/hashicorp/external/2.3.5/docs/data-sources/external) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix)

Description: Substring used to prefix resources created by this module

Type: `string`

### <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id)

Description: ID of subnet where instance should be placed

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_additional_clountinit_config_parts"></a> [additional\_clountinit\_config\_parts](#input\_additional\_clountinit\_config\_parts)

Description:     Cloudinit configuration files to include in user data. See https://cloudinit.readthedocs.io/en/latest/explanation/format.html"

Type:

```hcl
list(object({
    filename     = string
    content_type = string
    content      = string
  }))
```

Default: `[]`

### <a name="input_ami_search_filters"></a> [ami\_search\_filters](#input\_ami\_search\_filters)

Description:     List of filters to be applied to AMI search. Note that changing the OS distribution may have unintended consequences, as user data scripts have only been tested in RHEL 10.x.

Type:

```hcl
list(object({
    name   = string
    values = list(string)
  }))
```

Default:

```json
[
  {
    "name": "name",
    "values": [
      "RHEL-10.*"
    ]
  },
  {
    "name": "architecture",
    "values": [
      "x86_64"
    ]
  }
]
```

### <a name="input_cpu_options"></a> [cpu\_options](#input\_cpu\_options)

Description:     CPU options to pass to instance template.  
    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html

Type:

```hcl
object({
    core_count       = number
    threads_per_core = number
  })
```

Default:

```json
{
  "core_count": 1,
  "threads_per_core": 2
}
```

### <a name="input_instance_role_name"></a> [instance\_role\_name](#input\_instance\_role\_name)

Description:     Friendly name of IAM role to attach to instance profile. Defaults to creating bespoke role with AmazonSSMManagedInstanceCore managed policy attached.

Type: `string`

Default: `null`

### <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type)

Description:     EC2 instance type.  
    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html

Type: `string`

Default: `"m4.large"`

### <a name="input_key_name"></a> [key\_name](#input\_key\_name)

Description: Name of SSH key pair installed on instance

Type: `string`

Default: `null`

### <a name="input_management_lambda_schedule_expression"></a> [management\_lambda\_schedule\_expression](#input\_management\_lambda\_schedule\_expression)

Description:     Schedule expression to pass to EventBridge Scheduler for management Lambda invocation. If null, the Lambda will not be scheduled to automatically run.  
    See https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html for more information

Type: `string`

Default: `"rate(14 days)"`

### <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids)

Description:     List of security group IDs to attach to the instance. If no list is provided, a bespoke Security Group will automatically be created with all egress permitted and no ingress permitted.

Type: `list(string)`

Default: `null`

### <a name="input_tag_specifications"></a> [tag\_specifications](#input\_tag\_specifications)

Description:     Tags to be passed to instance launch template, in addition to provider-level default tags, which will automatically be merged in.  
    See https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_LaunchTemplateTagSpecificationRequest.html for a list of valid resource types.

Type: `map(map(string))`

Default:

```json
{
  "instance": {
    "Patch Group": "na",
    "backup": "na",
    "os": "rh10",
    "platform": "linux",
    "schedulev2": "na"
  },
  "volume": {}
}
```

### <a name="input_user_volume_id"></a> [user\_volume\_id](#input\_user\_volume\_id)

Description: ID of EBS volume to attach to instance. By default, a new EBS volume will be created

Type: `string`

Default: `null`

### <a name="input_user_volume_iops"></a> [user\_volume\_iops](#input\_user\_volume\_iops)

Description: Number input/output operations per second (IOPS) provisioned to user volume

Type: `number`

Default: `1250`

### <a name="input_user_volume_size"></a> [user\_volume\_size](#input\_user\_volume\_size)

Description: Size, in GiB, of the user volume

Type: `number`

Default: `100`

## Outputs

The following outputs are exported:

### <a name="output_ebs_volume_arn"></a> [ebs\_volume\_arn](#output\_ebs\_volume\_arn)

Description: n/a

### <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn)

Description: n/a

### <a name="output_proto_id"></a> [proto\_id](#output\_proto\_id)

Description: n/a
<!-- END_TF_DOCS -->