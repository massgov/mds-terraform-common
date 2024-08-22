output "jump_box_instance" {
  value = aws_instance.this.id
}

output "jump_box_security_group" {
  value = aws_security_group.this.id
}
