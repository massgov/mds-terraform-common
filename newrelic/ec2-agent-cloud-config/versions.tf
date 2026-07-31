terraform {
  required_version = ">= 1.5.0"
  required_providers {
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
}
