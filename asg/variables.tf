variable "name" {
  type        = string
  description = "The name to apply to the instance and autoscaling group"
}

variable "ami" {
  type        = string
  description = "The AMI ID to use for the instances. Keep this at the default value to automatically receive AMI updates to Amazon Linux 2"
  // AMI Built from packer/base.json
  default = "ami-0e8eb11a5429219ed"
}

variable "capacity" {
  type        = string
  description = "The number of instances to launch."
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "The instance type to use (eg: t3.nano)"
  default     = "t3.nano"
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups to apply to the instances."
  default     = []
}

variable "policies" {
  type        = list(string)
  description = "IAM Policies to attach to the instances."
  default     = []
}

variable "user_data" {
  type        = string
  description = "Base 64 encoded user data to run on instances at creation time"
  default     = ""
}

variable "subnets" {
  type        = list(string)
  description = "Subnets to launch instances into"
  default     = []
}

variable "keypair" {
  type        = string
  description = "The name of an SSH keypair to attach to all instances."
}

variable "target_group_arns" {
  type        = list(string)
  description = "A list of target group ARNs to pass to the ASG. See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#target_group_arns"
  default     = []
}

variable "load_balancers" {
  type        = list(string)
  description = "A list of load balancers to pass to the ASG. See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#load_balancers"
  default     = []
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
  description = "The value to use for the instance scheduling tag (schedulev2). Defaults to `na` for ASG instances, because ASGs should be scheduled via the ASG scheduler."
  default     = "na"
}

variable "instance_backup" {
  type        = string
  description = "Backup instructions for EC2 instances"
  default     = "na"
}

variable "instance_patch_group" {
  type        = string
  description = "Patch group to apply to EC2 instances."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all instances."
  default = {
  }
}

variable "block_devices" {
  type = list(object({
    device_name           = string,
    delete_on_termination = bool,
    encrypted             = bool,
    iops                  = number,
    snapshot_id           = string,
    throughput            = number,
    volume_size           = number,
    volume_type           = string
  }))
  description = "List of block_device_mappings for the launch template. See the `block_device_mappings` block in the aws_launch_template resource for descriptions of the fields."
  default = [
    {
      device_name           = "/dev/xvda",
      delete_on_termination = true,
      encrypted             = false,
      iops                  = null,
      snapshot_id           = null,
      throughput            = null,
      volume_size           = 30,
      volume_type           = "gp2"
    }
  ]
}

variable "amazon_ecs_managed_tag" {
  type        = bool
  description = "Whether or not to include the AmazonECSManaged tag."
  default     = true
}
