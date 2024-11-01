variable "name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to use for created resources"
  default = {
  }
}

variable "vpc" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "instance_type" {
  type        = string
  description = "The instance type to launch."
}

variable "capacity" {
  type        = string
  description = "The number of instances to launch."
  default     = "1"
}

variable "keypair" {
  type        = string
  description = "The name of the SSH keypair to attach to the instances."
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups to attach to the instances."
  default     = []
}

variable "policies" {
  type        = list(string)
  description = "Custom policies for the ECS Cluster."
  default     = []
}

variable "volume_size" {
  type        = string
  description = "The EBS volume size to use for the root EBS volume"
  default     = 30
}

variable "volume_encryption" {
  type        = string
  description = "A boolean indicating whether to encrypt the root EBS volume or not."
  default     = false
}

variable "schedule" {
  type        = string
  description = "A boolean indicating whether to automatically schedule the ASG according to the `schedule_down` and `schedule_up` variables."
  default     = false
}

variable "schedule_down" {
  type        = string
  description = "A cron expression indicating when to schedule the ASG to scale down to 0 instances (defaults to 7PM EST weekdays)."
  default     = "59 23 * * 1-5"
}

variable "schedule_up" {
  type        = string
  description = "A cron expression indicating when to schedule the ASG to scale up to $capacity instances (defaults to 7AM EST weekdays)"
  default     = "00 12 * * 1-5"
}

variable "instance_schedule" {
  type        = string
  description = "The schedule on which to start and stop EC2 instances. Can be `na` or `1100;2300;utc;weekdays`, depending on whether this is a dev or prod environment."
}

variable "instance_backup" {
  type        = string
  description = "Backup instructions for EC2 instances"
}

variable "instance_patch_group" {
  type        = string
  description = "Patch group to apply to EC2 instances."
}

variable "ami" {
  type        = string
  description = "AMI to use for cluster instances."
}

variable "include_ami_device_names" {
  type        = list(string)
  description = "List of AMI devices for which to include in the `block_device_mappings`."
}

variable "ami_volumes_delete_on_termination" {
  type        = bool
  description = "Whether to set the `delete_on_termination` flag for volumes included from the AMI."
  default     = true
}

variable "additional_cloudinit_configs" {
  type        = list(string)
  description = <<-DESC
    Additional cloud-init configuration content to be included in the user_data provided to the cluster's autoscaling group. Additional
    configs are merged with the default cloud-init file using the list(append)+dict(no_replace, recurse_list)+str(append)
    strategy. See https://cloudinit.readthedocs.io/en/latest/reference/merging.html#built-in-mergers for more informaiton.
  DESC
  default     = []
}

variable "amazon_ecs_managed_tag" {
  type        = bool
  description = "Whether or not to include the AmazonECSManaged tag to the autoscaling group."
  default     = true
}
