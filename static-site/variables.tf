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
variable "origin_request_lambda_arn" {
  type        = "string"
  description = "Lambda origin-request arn to associate with the CloudFront."

}

// lambda to associate with a CloudFront distribution
variable "origin_response_lambda_arn" {
  type        = "string"
  description = "Lambda origin-response arn to associate with the CloudFront."

}

// error document
variable "error_document" {
  default = "/404.html"
  description = "The error document being used for errors."
}

// tags
variable "tags" {
  type    = "map"
  default = {}
}
