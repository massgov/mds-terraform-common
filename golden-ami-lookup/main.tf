data "aws_caller_identity" "current" {}

# Default AMI to use when none is specified.
data "aws_ami" "golden_ami" {
  most_recent = true
  name_regex  = "^itd-mgt-ssr-golden-aws-linux-2"
  owners = [
    coalesce(var.owner_account_id, data.aws_caller_identity.current.account_id)
  ]
}
