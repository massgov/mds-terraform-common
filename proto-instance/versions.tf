terraform {
  required_version = ">= 1.13"
  required_providers {
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "2.3.7"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
