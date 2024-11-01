variable "vpc_id" {
  type        = string
  description = "The VPC to launch the instance in."
}

variable "subnet_id" {
  type        = string
  description = "The VPC subnet to launch the instance in."
}

variable "ami" {
  type        = string
  description = "The ami to use for the jump box. If the SSM Agent is not already installed on the ami, it should be installed through the user_data variable."
}

variable "name" {
  type        = string
  description = "Name to use for the instance."
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the instance."
  default     = "t4g.nano"
}

variable "instance_tags" {
  type        = map(string)
  description = "Additional tags to apply to the EC2 instance."
  default     = {}
}

variable "volume_size" {
  type        = number
  description = "Size of the root volume in gibibytes."
  default     = null
  nullable    = true
}

variable "volume_type" {
  type        = string
  description = "Volume type for the root volume."
  default     = null
  nullable    = true
}

variable "user_data" {
  type        = string
  description = "User data to use when creating the instance."
  default     = null
}

