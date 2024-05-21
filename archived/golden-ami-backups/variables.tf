variable "name_prefix" {
  type        = string
  description = "Name prefix to use for the Lambda function and AMI backup"
}

variable "human_name" {
  type        = string
  description = "Human-readable name for the Lambda function"
}

variable "source_image_parameter_arn" {
  type        = string
  description = "ARN of Parameter Store parameter referring to Golden (source) AMI"
}

variable "parent_account_ebs_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt EBS volumes in the parent (origin) account"
  default     = "arn:aws:kms:us-east-1:704819628235:key/52e13e09-cd15-42a5-804e-f2e47041913e"
}

variable "parameter_store_key_alias" {
  type        = string
  description = "The KMS key alias that is used to encrypt Parameter Store parameters in the target account"
  default     = "alias/parameter_store_key"
}

variable "ebs_key_alias" {
  type        = string
  description = "The KMS key alias that is used to encrypt EBS volumes in the target account"
  default     = "alias/aws/ebs"
}

variable "error_topic_arn" {
  type        = string
  description = "SNS Topic ARN to use when sending error messages"
}

variable "tags" {
  type    = map(string)
  default = {}
}
