# aws region
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

// get index.html lambda
variable "always_get_index_html_lambda" {
  type    = "string"
  default = "AlwaysRequestIndexHTML"
  description = "The lambda that always get index.html for sites."
}

// add headers lambda
variable "s3_edge_header_lambda" {
  type    = "string"
  default = "s3_edge_header"
  description = "The lamda that adds s3 origin headers."
}

variable "tags" {
  type    = "map"
  default = {}
}
