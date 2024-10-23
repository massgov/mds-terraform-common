variable "state_bucket_name" {
  description = "The name of the S3 bucket to store the Terraform state file"
  type        = string
  nullable    = true
  default     = null
}

variable "use_kms_key" {
  description = "Whether to create a KMS key for encrypting the Terraform state file"
  type        = bool
  default     = true
}

variable "kms_key_name" {
  description = "The alias of the KMS key to use for encrypting the Terraform state file"
  type        = string
  default     = "tf-state-bucket-sse-key"
}

variable "lock_table_name" {
  description = "The name of the DynamoDB table to use for locking Terraform state"
  type        = string
  default     = "terraform-state-lock"
}

variable "iam_policy_path" {
  description = "The path to use for the IAM policies"
  type        = string
  default     = "/soe/"
}

variable "create_plan_policy" {
  description = "Whether to create a policy that allows the Terraform state bucket to be accessed for plan operations"
  type        = bool
  default     = true
}

variable "create_apply_policy" {
  description = "Whether to create a policy that allows the Terraform state bucket to be accessed for apply operations"
  type        = bool
  default     = true
}
