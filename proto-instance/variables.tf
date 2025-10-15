variable "name_prefix" {
  type        = string
  description = "Substring used to prefix resources created by this module"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "Prefix should be an alphanumeric string not ending in a dash or underbar."
  }
}

variable "cpu_options" {
  type = object({
    core_count       = number
    threads_per_core = number
  })
  description = "CPU options to pass to instance template. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html"
  default = {
    core_count       = 1
    threads_per_core = 2
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html"
  default     = "m4.large"
}

variable "subnet_id" {
  type        = string
  description = "ID of subnet where instance should be placed"
}

variable "security_group_ids" {
  type        = list(string)
  description = <<EOF
    List of security group IDs to attach to the instance. If no list is provided, a bespoke Security
    Group will automatically be created with all egress permitted and no ingress permitted.
  EOF
  default     = null
}

variable "management_lambda_schedule_expression" {
  type = string
  description = <<EOF
    Schedule expression to pass to EventBridge Scheduler for management Lambda invocation. If null, the
    Lambda will not be scheduled to automatically run. See
    https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html for more information
  EOF
  default = "rate(14 days)"
}

variable "ami_search_filters" {
  type = list(object({
    name   = string
    values = list(string)
  }))
  description = <<EOF
    List of filters to be applied to AMI search. Note that changing the OS distribution may
    have unintended consequences, as user data scripts have only been tested in RHEL 10.x.
  EOF
  default = [
    {
      name   = "name"
      values = ["RHEL-10.*"]
    },
    {
      name   = "architecture",
      values = ["x86_64"]
    }
  ]
}

variable "tag_specifications" {
  type        = map(map(string))
  description = <<EOF
    Tags to be passed to instance launch template, in addition to provider-level default tags,
    which will automatically be merged in. See https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_LaunchTemplateTagSpecificationRequest.html
    for a list of valid resource types.
  EOF
  default = {
    "instance" = {
      "backup"      = "na"
      "os"          = "rh10"
      "Patch Group" = "na"
      "platform"    = "linux"
      "schedulev2"  = "na"
    }
    "volume" = {}
  }
}

variable "key_name" {
  type        = string
  description = "Name of SSH key pair installed on instance"
  default     = null
}

variable "user_volume_id" {
  type        = string
  description = "ID of EBS volume to attach to instance. By default, a new EBS volume will be created"
  default     = null
}

variable "user_volume_size" {
  type        = number
  description = "Size, in GiB, of the user volume"
  default     = 100
}

variable "user_volume_iops" {
  type        = number
  description = "Number input/output operations per second (IOPS) provisioned to user volume"
  default     = 1250
  validation {
    condition     = var.user_volume_iops <= 64000
    error_message = "EBS does not support more than 64000 IOPS"
  }
}

variable "instance_role_name" {
  type        = string
  description = <<EOF
    Friendly name of IAM role to attach to instance profile. Defaults to creating bespoke role
    with AmazonSSMManagedInstanceCore managed policy attached.
  EOF
  default     = null
}

variable "additional_clountinit_config_parts" {
  type = list(object({
    filename     = string
    content_type = string
    content      = string
  }))
  description = <<EOF
    Cloudinit configuration files to include in user data. See
    https://cloudinit.readthedocs.io/en/latest/explanation/format.html"
  EOF
  default     = []
}
