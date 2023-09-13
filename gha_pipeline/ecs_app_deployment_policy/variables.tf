variable "project_name" {
  type        = string
  description = "The name of the project (alphanumeric characters only)"
}

variable "chamber_key" {
  type        = string
  description = "ARN of a KMS key that's used for encrypting chamber secrets"
}

variable "namespace" {
  type        = string
  description = "A lowercase, alphanumeric namespace that describes the application.  This will be used to isolate secrets."
}

variable "region" {
  type = string
  description = "The AWS region to scope access to (defaults to current region)."
  default = ""
}

variable "account_id" {
  type = string
  description = "The AWS account ID to scope access to (defaults to current account)."
  default = ""
}

variable "logging_namespace" {
  type = string
  description = "The logging namespace for logs."
  default = ""
}

variable "ecr_resources" {
  description = "Resource names for ECR repositories this policy will access."
  type = list(string)
  default = ["*"]
}
