// The ARN of the AMI
output "ami_id" {
  value = data.aws_ami.golden_ami.image_id
}
