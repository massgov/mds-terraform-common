terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      version = ">= 5.26.0"
    }
    semvers = {
      source  = "anapsix/semvers"
      version = ">= 0.8.0"
    }
  }
}
