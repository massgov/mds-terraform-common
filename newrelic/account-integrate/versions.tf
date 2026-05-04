terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.80"
    }

  }
}
