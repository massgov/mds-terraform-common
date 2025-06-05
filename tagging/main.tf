
data "terraform_remote_state" "tags" {
  backend = "s3"
  config = {
    bucket = "itd-mgt-ssr-tagging.secure.digital.mass.gov"
    key    = "tf/state/tagging.tfstate"
    region = "us-east-1"
  }
}

# Mapping of tag names to tag values
output "tags" {
  value = merge(var.additional_tags, lookup(data.terraform_remote_state.tags.outputs.tags, var.org, {})[var.repo])
}

