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
variable "origin_request" {
  type        = "string"
  description = "The lambda arn to associate with the CloudFront Distribution."

}

// lambda to associate with a CloudFront distribution
variable "origin_response" {
  type        = "string"
  description = "The lambda arn to associate with the CloudFront Distribution."

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
