variable "patch_environments" {
  description = "Existing environment tag values that are eligible for patching."
  type        = set(string)
}

variable "patch_schedule_expression" {
  description = "State Manager schedule expression."
  type        = string
}

variable "apply_only_at_cron_interval" {
  description = "boolean if you want to apply only at the specified patch_schedule_expression/interval"
  type        = bool
  default     = true
}
