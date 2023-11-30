# Default AMI to use when none is specified.
data "aws_ami" "golden_ami" {
  most_recent = true
  name_regex  = "^itd-mgt-golden-aws-linux2"
  owners      = ["786775234217"]
}
