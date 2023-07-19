variable "ami" {
  type        = string
  description = "The AMI to copy devices from."
}

variable "device_filter_type" {
  type        = string
  description = "How to filter block devices. When `include`, only the devices in `device_names` will be returned. When `exclude`, all devices EXCEPT the devices in `device_names` (and the root device, if that option is set) will be returned."

  validation {
    condition     = var.device_filter_type == "include" || var.device_filter_type == "exclude"
    error_message = "The device_filter_type variable should be either `include` or `exclude`."
  }
}

variable "device_names" {
  type        = list(string)
  description = "List of AMI device names to use for filtering. When `device_filter_type` is `exclude`, all devices except those in the list will be included in the output. When `device_filter_type` is `include`, only devices matching the names in the list will be included."
  default     = []
}

variable "exclude_root_device" {
  type        = bool
  description = "Whether or not to exclude the root device. This has no effect when device_filter_type is `include`."
  default     = false
}

variable "force_delete_on_termination" {
  type        = bool
  description = "Whether to set (to true) the `delete_on_termination` flag for the returned devices."
  default     = false
}
