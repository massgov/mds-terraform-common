terraform {
  required_version = ">= 1.13"
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
