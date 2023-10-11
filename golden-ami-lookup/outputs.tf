// The ARN of the AMI
output "ami_arn" {
  value = data.aws_ami.golden_ami.arn
}
