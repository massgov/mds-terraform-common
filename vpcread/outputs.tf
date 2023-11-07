output "vpc" {
  value = data.aws_vpc.default.id
}

output "public_subnets" {
  value = data.aws_subnets.public.ids
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}

output "db_subnets" {
  value = data.aws_subnets.db.ids
}

