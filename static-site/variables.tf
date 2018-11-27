# aws region
provider "aws" {
  region = "us-east-1"
}

// new statis sites are subdomains under *.digital.mass.gov
variable "sub_domain_name" {
  type        = "string"
  description = "The full sub domain name"
}
