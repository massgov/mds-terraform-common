variable "name" {
  type        = "string"
  description = "The name to apply to the instance and autoscaling group"
}

variable "ami" {
  type        = "string"
  description = "The AMI ID to use for the instances. Keep this at the default value to automatically receive AMI updates to Amazon Linux 2"
  // amzn2-ami-hvm-2.0.20181114-x86_64-ebs
  default     = "ami-0b8d0d6ac70e5750c"
}

variable "capacity" {
  type        = "string"
  description = "The number of instances to launch."
  default     = 1
}

variable "instance_type" {
  type        = "string"
  description = "The instance type to use (eg: t3.nano)"
  default     = "t3.nano"
}

variable "security_groups" {
  type        = "list"
  description = "Security groups to apply to the instances."
  default     = []
}

variable "policies" {
  type        = "list"
  description = "IAM Policies to attach to the instances."
  default     = []
}

variable "user_data" {
  type        = "string"
  description = "Base 64 encoded user data to run on instances at creation time"
  default     = ""
}

variable "subnets" {
  type        = "list"
  description = "Subnets to launch instances into"
  default     = []
}

variable "keypair" {
  type        = "string"
  description = "The name of an SSH keypair to attach to all instances."
}

variable "instance_schedule" {
  type        = "string"
  description = "The schedule on which to start and stop EC2 instances. Can be `na` or `1100;2300;utc;weekdays`, depending on whether this is a dev or prod environment."
}

variable "instance_backup" {
  type        = "string"
  description = "Backup instructions for EC2 instances"
}

variable "instance_patch_group" {
  type        = "string"
  description = "Patch group to apply to EC2 instances."
}

variable "tags" {
  type        = "map"
  description = "Additional tags to apply to all instances."
  default     = {}
}
