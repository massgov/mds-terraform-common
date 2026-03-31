variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_sg_mappings" {
  type        = map(string)
  description = "Map of VPC names to security group names. The Lambda will look up the instance's VPC name and attach the corresponding security group."
}
/* example mapping
  vpc_sg_mappings = {
    "VPC-EOTSS-Digital-NonProd" = "tenable-eotss-core-scanners-sg-VPC-EOTSS-Digital-NonProd"
    "VPC-EOTSS-Digital-Prod"    = "tenable-eotss-core-scanners-sg-VPC-EOTSS-Digital-Prod"
    "VPC-EOTSS-Digital-Mgt"     = "tenable-eotss-core-scanners-sg-VPC-EOTSS-Digital-Mgt"
  }
  */

variable "lambda_function_name" {
  type    = string
  default = "ec2-scanner-sg-remediator"
}

variable "scanner_secret_parameter_name" {
  type        = string
  description = "Full SSM Parameter Store name for the SecureString secret, for example /scanner/prod/api-token."
  default     = "/apps/nessus-tenable-scanning-public-key"
}
