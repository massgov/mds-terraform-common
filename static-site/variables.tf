// aws region
provider "aws" {
  region = "us-east-1"
}

// root domain name
variable "zone_id" {
  type        = "string"
  description = "The zone that domain will be added to."
}

// new site domain name
variable "domain_name" {
  type        = "string"
  description = "The full domain name being added."
}

// lambda to associate with a CloudFront distribution
variable "lambda_arn" {
  type        = "string"
  description = "The lambda arn to associate with the CloudFront Distribution."

}

// tags
variable "tags" {
  type    = "map"
  default = {}
}
