terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 4.67 is the first version that allows `metric_names` for
      # the include_filters
      version = ">= 4.67"
    }

    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 2.44"
    }
  }
}
