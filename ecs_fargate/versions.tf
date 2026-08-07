
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Needed for lambda module
      version = ">= 5.26.0"
    }
  }
}
