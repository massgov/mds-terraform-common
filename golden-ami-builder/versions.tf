terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      version = ">= 4.58"
    }
    semvers = {
      source = "anapsix/semvers"
      version = ">= 0.7.1"
    }
  }
}
