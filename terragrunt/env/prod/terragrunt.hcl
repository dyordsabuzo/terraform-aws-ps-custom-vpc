include {
    path = find_in_parent_folders()
}

terraform {
    source = "../../.."

    before_hook "select_workspace" {
        commands = ["init"]
        execute = ["terraform", "workspace", "select", "${local.workspace}"]
    }
}

locals {
    common = read_terragrunt_config(find_in_parent_folders("common.hcl"))

    vpc_cidr = "10.1.0.0/20"
    az_count = 2
    workspace = "prod"

    public_superset  = cidrsubnet(local.vpc_cidr, 2, 0)
    private_superset = cidrsubnet(local.vpc_cidr, 2, 1)
    public_subnets = [for index in range(local.az_count) :
        cidrsubnet(local.public_superset, 2, index)
    ]
    private_subnets = [for index in range(local.az_count) :
        cidrsubnet(local.private_superset, 2, index)
    ]
}

inputs = {
    region = "us-east-1"
  vpc_cidr_block          = local.vpc_cidr
  public_subnets          = local.public_subnets
  resource_identifier     = local.workspace
  availability_zone_count = local.az_count
  private_subnets         = local.private_subnets
  tags                    = merge(local.common.locals.tags, {
      environment = local.workspace
  })
}