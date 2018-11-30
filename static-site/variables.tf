# aws region
provider "aws" {
  region = "us-east-1"
}

// root domain name
variable "root_domain_name" {
  default = "digital.mass.gov"
}

// new statis sites are subdomains under *.digital.mass.gov
variable "sub_domain_name" {
  type        = "string"
  description = "The full sub domain name"
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "always_get_index_html_lambda" {
  type    = "string"
  default = "AlwaysRequestIndexHTML"
  description = "The lamdas that alwasy gets index.html for static sites"
}
