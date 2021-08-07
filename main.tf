resource "aws_vpc" "vpc" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  cidr_block           = var.vpc_cidr_block
  tags = merge(local.tags, {
    Name = var.resource_identifier
  })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(local.tags, {
    Name = var.resource_identifier
  })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(local.tags, {
    Name = var.resource_identifier
  })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway

  timeouts {
    create = "5m"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = toset(var.public_subnets)
  cidr_block              = each.key
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone = element(
    local.azs,
    index(var.public_subnets, each.key)
  )
  tags = merge(local.tags, {
    Name = format("%s-public-%s",
      var.resource_identifier,
    index(var.public_subnets, each.key))
  })
}

resource "aws_route_table_association" "public_rt_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}
