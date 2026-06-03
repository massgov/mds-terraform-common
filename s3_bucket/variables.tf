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
  description = <<EOF
    Should this bucket be publicly accessible? Default is false. Note that configuring
    a bucket as public with NOT affect bucket policy, but merely allow callers to grant
    public access using the custom_policy variable. CAUTION: Only things like CSS/JS
    assets for a public web site should ever be publicly accessible! Use locked-down/private
    S3 buckets by default!
  EOF
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

variable "permit_non_ssl_requests" {
  type        = bool
  description = "Allow non-SSL requests? Default is false (only allow SSL). CAUTION: Only disable SSL if you have a very good reason!"
  default     = false
}

variable "kms_policy" {
  type        = string
  description = "The KMS key policy JSON"
  default     = ""
}

variable "deletion_window_in_days" {
  type        = number
  description = "Length of time (in days) the KMS key will be retained when a deletion is scheduled. Only used if a new KMS key is created by this module."
  default     = 30
}

# Note: AWS creates a default KMS key policy if you don't provide one.
### example for kms_policy allowing full access to a specific account:
#  kms_policy =  <<POLICY
# {
#   "Version": "2012-10-17",
#   "Id": "default",
#   "Statement": [
#     {
#       "Sid": "DefaultAllow",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::123456789012:root"
#       },
#       "Action": "kms:*",
#       "Resource": "*"
#     }
#   ]
# }
# POLICY
# }
