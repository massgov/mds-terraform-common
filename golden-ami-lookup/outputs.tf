// The ARN of the AMI
output "ami_id" {
  value = data.aws_ami.golden_ami.image_id
}

output "ami_name_prefix" {
  value = local.name_prefix
}

output "ami_instance_tags" {
  value = {
    "platform" = "linux"
    "os"       = "al2"
  }
}
