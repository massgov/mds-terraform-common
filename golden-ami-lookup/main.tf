# Default AMI to use when none is specified.
data "aws_ami" "golden_ami" {
  most_recent = true
  name_regex  = "^eotss-aws2-cis-lvm_"
  owners      = ["704819628235"]
}
