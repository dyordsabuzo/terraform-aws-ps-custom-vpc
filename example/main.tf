module "my_vpc" {
  source                  = "../"
  vpc_cidr_block          = local.vpc_cidr
  public_subnets          = local.public_subnets
  resource_identifier     = var.resource_identifier
  availability_zone_count = local.az_count
  private_subnets         = local.private_subnets
  tags                    = local.tags
}
