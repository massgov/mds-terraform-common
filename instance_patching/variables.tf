variable "patch_environments" {
  description = "Existing environment tag values that are eligible for patching."
  type        = set(string)
}

variable "patch_schedule_expression" {
  description = "State Manager schedule expression."
  type        = string
}

variable "additional_container_host_tag_keys" {
  description = "Additional EC2 tag keys that identify ECS/EKS hosts."
  type        = set(string)
  default     = []
}
