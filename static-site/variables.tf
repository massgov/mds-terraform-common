# aws region
provider "aws" {
  region = "us-east-1"
}

// root domain name
variable "root_domain_name" {
  default = "digital.mass.gov"
}

// new site domain name
variable "domain_name" {
  type        = "string"
  description = "The full domain name"
}

variable "always_get_index_html_lambda" {
  type    = "string"
  default = "AlwaysRequestIndexHTML"
  description = "The lambda that always get index.html for static sites"
}

variable "s3_edge_header_lambda" {
  type    = "string"
  default = "s3_edge_header"
  description = "The lamda that adds s3 origin headers"
}

variable "tags" {
  type    = "map"
  default = {}
}
