variable "name_prefix" {
  type        = string
  description = "A name prefix to use for created resources."
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "Prefix should only contain alphanumeric characters and (optionally) dashes. It must not end in a dash."
  }
}

variable "aws_account_name" {
  type        = string
  description = "The account name for the AWS account."
}

variable "newrelic_account_id" {
  type        = string
  description = "The account number for the New Relic account."
}

variable "newrelic_iam_role_arn" {
  type        = string
  description = "Previous created Iam Role for New Relic Integration"
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
