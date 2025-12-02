variable "policy_file_prefix" {
  description = "name that the list of policy files will be prefixed with"
  type        = string
}

variable "state_bucket_name" {
  description = "name of the S3 bucket for Terraform state"
  type        = string
}

variable "current_apply_role_name" {
  description = "name of the role used to apply this terraform configuration"
  type        = string
}
