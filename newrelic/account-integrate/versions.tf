terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 3.95.2"
    }

  }
}
