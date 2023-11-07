output "vpc" {
  value = data.aws_vpc.default.id
}

output "public_subnets" {
  value = data.aws_subnet.public.ids
}

output "private_subnets" {
  value = data.aws_subnet.private.ids
}

output "db_subnets" {
  value = data.aws_subnet.db.ids
}

