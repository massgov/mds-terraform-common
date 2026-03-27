variable "region" {
  type    = string
  default = "us-east-1"
}

variable "required_security_group_id" {
  type        = string
  description = "Security group that must always be attached to all target EC2 instances/ENIs."
}

variable "lambda_function_name" {
  type    = string
  default = "ec2-scanner-sg-remediator"
}

variable "scanner_secret_parameter_name" {
  type        = string
  description = "Full SSM Parameter Store name for the SecureString secret, for example /scanner/prod/api-token."
  default = "/apps/nessus-tenable-scanning-public-key"
}
