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
  description = <<EOF
    CPU options to pass to instance template.
    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html
  EOF
  default = {
    core_count       = 1
    threads_per_core = 2
  }
}

variable "instance_type" {
  type        = string
  description = <<EOF
    EC2 instance type.
    See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/cpu-options-supported-instances-values.html
  EOF
  default     = "m4.large"
}

variable "subnet_id" {
  type        = string
  description = "ID of subnet where instance should be placed"
}

variable "security_group_ids" {
  type        = list(string)
  description = <<EOF
    List of security group IDs to attach to the instance. If no list is provided, a bespoke Security Group will automatically be created with all egress permitted and no ingress permitted.
  EOF
  default     = null
}

variable "ami_search_filters" {
  type = list(object({
    name   = string
    values = list(string)
  }))
  description = <<EOF
    List of filters to be applied to AMI search. Note that changing the OS distribution may have unintended consequences, as user data scripts have only been tested in RHEL 10.x.
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
    Tags to be passed to instance launch template, in addition to provider-level default tags, which will automatically be merged in.
    See https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_LaunchTemplateTagSpecificationRequest.html for a list of valid resource types.
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

variable "volume_attachments" {
  type        = map(string)
  description = "Mapping of EBS volume IDs to device names"
  default     = {}
}

variable "additional_instance_profile_policy_arns" {
  type        = map(string)
  description = <<EOF
    Mapping of short names to IAM policy ARNs. Policies will be attached to instance profile. Short
    names do not affect behavior, but are merely used by terraform to track changes.
  EOF
  default     = {}
}

variable "additional_clountinit_config_parts" {
  type = list(object({
    filename     = string
    content_type = string
    content      = string
  }))
  description = <<EOF
    Cloudinit configuration files to include in user data. See https://cloudinit.readthedocs.io/en/latest/explanation/format.html"
  EOF
  default     = []
}
