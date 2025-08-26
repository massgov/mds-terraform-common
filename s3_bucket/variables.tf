variable "bucket_name" {
  type        = string
  description = "Name of the backet (random numbers will be appended at the end)."
  default     = "default-bucket"
}

variable "guarantee_uniqueness" {
  type        = bool
  description = "Append some random characters to the bucket name in order to guarantee global uniqueness?"
  default     = false
}

variable "bucket_region" {
  type        = string
  description = "Location of the bucket, such as `us-west-2` or `ca-central-1`."
  default     = "us-east-1"
}

variable "bucket_tags" {
  type        = map(string)
  description = "Optional tags for the bucket"
  default     = {}
}

variable "kms_encrypted" {
  type        = bool
  description = "Should the bucket objects be server-side encrypted?"
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "Optional KMS Key ARN to use for S3 bucket encryption. If blank, and if var.encrypted == true, then this module will create a new KMS Key to encrypt the S3 bucket."
  default     = ""
}

variable "important" {
  type        = bool
  description = "Should the bucket have versioning enabled, force_destroy disabled, and any other future protections due to its importance?"
  default     = false
}

variable "public" {
  type        = bool
  description = "Should this bucket be publicly accessible? Default is false. CAUTION: Only things like CSS/JS assets for a public web site should ever be publicly accessible! Use locked-down/private S3 buckets by default!"
  default     = false
}

variable "log_prefix" {
  type        = string
  description = "A prefix for all log object keys."
  default     = "log/"
}

variable "enable_logging" {
  type        = bool
  description = "Should access logging be enabled for this bucket?"
  default     = false
}

variable "custom_policy" {
  type        = string
  description = "Optional custom bucket policy in JSON (as a string). If this is provided, it will override the default policy that is created."
  default     = ""
}
