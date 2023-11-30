variable "owner_account_id" {
  type        = "string"
  default     = null
  description = "ID of the AWS account that owns the Golden AMI. The current account's ID will be used if none is provided"
}
