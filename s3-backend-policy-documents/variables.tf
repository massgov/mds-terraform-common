variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket used for terraform state."
  nullable    = false
}

# Ideally we could just look up the default key for the bucket, but there is
# no way to do that from terraform.
variable "bucket_kms_key" {
  type        = string
  description = "Default bucket key for the state bucket."
  nullable    = false
}

variable "state_file_paths" {
  type        = list(string)
  description = "Paths where the state file will be saved."
  nullable    = false
}
