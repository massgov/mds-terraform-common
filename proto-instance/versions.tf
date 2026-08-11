terraform {
  required_version = ">= 1.13"
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0"
    }
  }
}
