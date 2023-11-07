data "aws_vpc" "default" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  tags = {
    Tier = "Public"
  }
}

data "aws_subnet" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_subnet" "db" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  tags = {
    Tier = "DBPrivate"
  }
}

