data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = coalesce(var.state_bucket_name, "terraform-state-${data.aws_caller_identity.current.account_id}")
}
