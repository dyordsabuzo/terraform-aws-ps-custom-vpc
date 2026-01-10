locals {
  azs = slice(data.aws_availability_zones.azs.names,
    0,
    var.availability_zone_count
  )

  nat_gateway_count = var.single_nat_gateway ? 1 : var.availability_zone_count
  nat_azs           = slice(local.azs, 0, local.nat_gateway_count)

  public_subnet_ids = [for key, public_subnet in aws_subnet.public_subnet : public_subnet.id]

  private_route_table_ids = [for key, route_table in aws_route_table.private_route_table : route_table.id]
}
