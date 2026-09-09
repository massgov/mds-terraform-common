variable "patch_environments" {
  description = "Existing environment tag values that are eligible for patching."
  type        = set(string)
}

variable "patch_schedule_expression" {
  description = "State Manager schedule expression."
  type        = string
}
