variable "name" {
  type        = string
  description = "The name of the project (alphanumeric characters only)"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the codebuild jobs"
}

variable "repository" {
  type        = string
  description = "The github repository URL"
}

variable "oauth_token" {
  type        = string
  description = "The github OAuth token to use when authenticating to github"
}

variable "build_image" {
  type        = string
  description = "The docker image to run builds in."
}

variable "chamber_key" {
  type        = string
  description = "ARN of a KMS key that's used for encrypting chamber secrets"
}

variable "namespace" {
  type        = string
  description = "A lowercase, alphanumeric namespace that describes the application.  This will be used to isolate secrets."
}

variable "failure_topics" {
  type        = list(string)
  description = "A list of SNS topics to publish to on build failure"
}

variable "region" {
  type = "string"
  description = "The AWS region to scope access to (defaults to current region)."
  default = ""
}

variable "account_id" {
  type = "string"
  description = "The AWS account ID to scope access to (defaults to current account)."
  default = ""
}

variable "plan_policy" {
  type = string
  description = "The ARN of an AWS IAM policy to use for 'plan' jobs."
  default = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

variable "apply_policy" {
  type = string
  description = "The ARN of an AWS IAM policy to use for 'apply' jobs."
  default = "arn:aws:iam::aws:policy/AdministratorAccess"
}

