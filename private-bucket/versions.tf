
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Can probably be used with lower versions, I think down to aws v2?
      # I have only tested it with v4 though
      version = ">= 4.53"
    }
  }
}
