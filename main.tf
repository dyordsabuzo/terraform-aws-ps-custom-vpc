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
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id

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

resource "aws_eip" "nat_elastic_ip" {
  for_each = toset(local.nat_azs)
  vpc      = true

  tags = merge(local.tags, {
    Name = format("%s-%s", var.resource_identifier, each.key)
  })
}

resource "aws_nat_gateway" "nat_gateway" {
  for_each      = aws_eip.nat_elastic_ip
  allocation_id = each.value.id
  subnet_id = element(local.public_subnet_ids,
    index(keys(aws_eip.nat_elastic_ip), each.key)
  )

  tags = merge(local.tags, {
    Name = format("%s-%s", var.resource_identifier, each.key)
  })

  depends_on = [
    aws_internet_gateway.internet_gateway
  ]
}

resource "aws_route_table" "private_route_table" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.vpc.id

  tags = merge(local.tags, {
    Name = format("%s-private-%s", var.resource_identifier, each.key)
  })
}

resource "aws_route" "private_route" {
  for_each               = toset(local.azs)
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_route_table[each.key].id
  nat_gateway_id         = aws_nat_gateway.nat_gateway[each.key].id

  timeouts {
    create = "5m"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = toset(var.private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.key
  availability_zone = element(local.azs, index(var.private_subnets, each.key))

  tags = merge(local.tags, {
    Name = format("%s-private-%s", var.resource_identifier, index(var.private_subnets, each.key))
  })
}

resource "aws_route_table_association" "private_route_association" {
  for_each  = aws_subnet.private_subnet
  subnet_id = each.value.id
  route_table_id = element(local.private_route_table_ids,
    index(keys(aws_subnet.private_subnet), each.key)
  )
}
