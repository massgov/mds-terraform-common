variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_sg_mappings" {
  type        = map(string)
  description = "Map of VPC names to security group names. The Lambda will look up the instance's VPC name and attach the corresponding security group."
}
/* example mapping (not real values)
  vpc_sg_mappings = {
    "VPC-EOTSS-D-NonProd" = "t-eotss-core-scanners-sg-VPC-NonProd"
    "VPC-EOTSS-D-Prod"    = "t-eotss-core-scanners-sg-VPC-Prod"
    "VPC-EOTSS-D-Mgt"     = "t-eotss-core-scanners-sg-VPC-Mgt"
  }
  */

variable "lambda_function_name" {
  type    = string
  default = "ec2-scanner-sg-remediator"
}

variable "scanner_secret_parameter_name" {
  type        = string
  description = "Full SSM Parameter Store name for the SecureString secret. Must start with '/'. Example: /scanner/prod/api-token"
  #adding validation so no forgetting starting '/'
  validation {
    condition     = can(regex("^/", var.scanner_secret_parameter_name))
    error_message = "The scanner_secret_parameter_name must start with a forward slash (/)."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt the scanner secret parameter. Use '*' to allow any key, or provide a full KMS key ARN or alias ARN."
  default     = "*"
}

variable "scanner_username" {
  type        = string
  description = "Username for the Nessus scanner user to be created on EC2 instances."
  default     = "nessus-user-massdigital"
}

variable "ssm_document_name" {
  type        = string
  description = "Name of the SSM document for scanner bootstrap."
  default     = "scanner-bootstrap-setup"
}
