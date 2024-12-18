terraform {
  required_version = "1.9.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.66.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.1"
    }
  }
}


