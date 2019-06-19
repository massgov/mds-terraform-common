output "vpc" {
  value = data.aws_vpc.default.id
}

output "public_subnets" {
  value = data.aws_subnet_ids.public.ids
}

output "private_subnets" {
  value = data.aws_subnet_ids.private.ids
}

output "db_subnets" {
  value = data.aws_subnet_ids.db.ids
}

