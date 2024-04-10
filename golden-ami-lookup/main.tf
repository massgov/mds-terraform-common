data "aws_caller_identity" "current" {}

locals {
  name_prefix = "itd-mgt-golden-aws-linux2"
}

# Default AMI to use when none is specified.
data "aws_ami" "golden_ami" {
  most_recent = true
  name_regex  = "^${local.name_prefix}"
  owners = [
    coalesce(var.owner_account_id, data.aws_caller_identity.current.account_id)
  ]
}
