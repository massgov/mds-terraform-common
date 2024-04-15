
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # This may work with earlier versions, however the lowest version
      # we have currently using it is v4.58.0
      version = ">= 4.58.0"
    }
  }
}
