locals {
  tags = {
    created_by = "terraform"
  }

  az_count = 3

  vpc_cidr = "10.11.0.0/20"

  public_superset  = cidrsubnet(local.vpc_cidr, 2, 0)
  private_superset = cidrsubnet(local.vpc_cidr, 2, 1)

  public_subnets = [for index in range(local.az_count) :
    cidrsubnet(local.public_superset, 2, index)
  ]

  private_subnets = [for index in range(local.az_count) :
    cidrsubnet(local.private_superset, 2, index)
  ]
}
