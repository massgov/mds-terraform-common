locals {
  # Single source of truth for the SSR tag registry bucket (EOTSS-Digital-SSR-Prod, 251246747079)
  registry_bucket = "ssr-tagging-prod-251246747079"
}

# Consumers feed this module's output into their provider's default_tags, so
# the registry read cannot use that provider without a cycle. It uses this
# module-local instance instead.
provider "aws" {
  alias  = "registry"
  region = "us-east-1"
}

data "aws_s3_object" "tags" {
  provider = aws.registry
  bucket   = local.registry_bucket
  key      = "tags/tags.json"
}

locals {
  managed_tags = jsondecode(data.aws_s3_object.tags.body)
}

# Mapping of tag names to tag values
output "tags" {
  value = merge(var.additional_tags, lookup(local.managed_tags, var.org, {})[var.repo])
}
