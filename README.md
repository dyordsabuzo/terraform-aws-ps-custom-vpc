# terraform-aws-ps-custom-vpc

Terraform module to create a customizable AWS VPC with public and private subnets, NAT gateway(s), routing, an Internet Gateway, and optional VPC Flow Logs delivered to CloudWatch Logs. 

This repository provides an opinionated, easy-to-drop-in VPC implementation supporting single or multiple AZs, optional flow logs, and single vs per-AZ NAT gateway behavior.

---

## Table of contents

- [Description](#description)
- [Features](#features)
- [Resources created](#resources-created)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Basic usage](#basic-usage)
- [Flow logs, CloudWatch & IAM](#flow-logs-cloudwatch--iam)
- [NAT gateway behavior](#nat-gateway-behavior)
- [Behavior details & assumptions](#behavior-details--assumptions)
- [Testing & development](#testing--development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Description

This module builds an AWS Virtual Private Cloud (VPC) with:

- A VPC with a top-level CIDR block.
- Public and private subnets (multi-AZ aware).
- An Internet Gateway and public route table.
- NAT Gateway(s) for private subnets (single shared NAT or NAT per AZ).
- Route tables and associations for public and private subnets.
- Optional VPC Flow Logs that publish to a CloudWatch Log Group (with IAM role & policy).

Use this module to provide a standard networking foundation for application stacks that need both public-facing and private resources.

---

## Features

- Configurable number of availability zones.
- Lists of public and private subnet CIDRs.
- Option for single NAT gateway (cheaper) or one NAT per AZ (HA).
- Optional VPC Flow Logs with CloudWatch retention configuration.
- Outputs `vpc_id` for downstream modules.

---

## Resources created

The module may create (depending on inputs):

- `aws_vpc` — VPC
- `aws_subnet` — public and private subnets
- `aws_internet_gateway` — Internet gateway for public subnets
- `aws_route_table` / `aws_route_table_association` — routing for public/private subnets
- `aws_nat_gateway` and `aws_eip` — NAT gateways and Elastic IP(s)
- `aws_cloudwatch_log_group`, `aws_iam_role`, `aws_iam_role_policy`, `aws_flow_log` — when flow logs enabled
- Data sources: `aws_availability_zones`, `aws_iam_policy_document`

(See module code for exact resource names and tags.)

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `region` | AWS region where resources will be created | `string` | n/a | yes |
| `vpc_cidr_block` | CIDR block for the VPC (e.g. `10.0.0.0/16`) | `string` | n/a | yes |
| `public_subnets` | List of CIDR blocks assigned to public subnets | `list(any)` | n/a | yes |
| `private_subnets` | List of CIDR blocks for private subnets | `list(any)` | `[]` | no |
| `availability_zone_count` | Number of AZs to provision (controls AZ usage) | `number` | `1` | no |
| `single_nat_gateway` | `true` = single NAT gateway; `false` = NAT per AZ | `bool` | `false` | no |
| `flow_logs` | Object controlling flow logs: `{ enabled = optional(bool), log_retention = optional(number) }` | `object` | `{ "enabled": false }` | no |
| `resource_identifier` | Optional identifier used to tag/name resources created by this module | `string` | `"default"` | no |

Notes:
- `public_subnets` is required. Provide one CIDR per public subnet you want.
- `private_subnets` is optional; if omitted, private subnets and NAT routes/GWs are not created.
- `availability_zone_count` controls how many AZs the module will use (it selects the first N AZs from the account/region).

---

## Outputs

| Name | Type | Description | Example |
|------|------|-------------|---------|
| `vpc_id` | `string` | The ID of the created VPC | `vpc-0a1b2c3d4e5f67890` |
| `public_subnets` | `list(string)` | The IDs of the public subnets created by the module | `["subnet-0123abcd", "subnet-4567efgh"]` |
| `private_subnets` | `list(string)` | The IDs of the private subnets created by the module (if any) | `["subnet-89ab1234", "subnet-cdef5678"]` |

Example of consuming these outputs from a root module:

```/dev/null/outputs.tf#L1-12
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
```

---

## Basic usage

Replace `source` with the actual module path (local path, Git URL, or registry).

```/dev/null/usage.tf#L1-30
module "vpc" {
  source = "../terraform-aws-ps-custom-vpc" # replace with your module source

  region                  = "us-east-1"
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnets          = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets         = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zone_count = 2
  single_nat_gateway      = false

  flow_logs = {
    enabled       = true
    log_retention = 14
  }

  resource_identifier = "myproject"
}
```

Example will:
- Create a `10.0.0.0/16` VPC
- Create two public and two private subnets across up to 2 AZs
- Create NAT gateways per AZ (`single_nat_gateway = false`)
- Enable VPC Flow Logs with 14-day CloudWatch retention

---

## Flow logs, CloudWatch & IAM

If `flow_logs.enabled = true`, the module will:

- Create a CloudWatch Log Group for VPC flow logs.
- Create an IAM role and inline policy allowing VPC Flow Logs to publish to CloudWatch.
- Create an `aws_flow_log` resource attached to the VPC.

`flow_logs.log_retention` (days) will be applied to the CloudWatch Log Group. If you need alternate destinations (S3, Kinesis) or a custom retention policy, adapt the module.

---

## NAT gateway behavior

- `single_nat_gateway = true`:
  - A single NAT Gateway is created with a single EIP.
  - All private subnet routes point to that NAT.
  - Lower cost; single point of egress failure.

- `single_nat_gateway = false`:
  - A NAT Gateway (and EIP) is created per AZ used.
  - Private subnets route to the NAT in their AZ.
  - More expensive; AZ-level redundancy for egress.

If `private_subnets` is empty, NAT Gateways and related resources are not created.

---

## Behavior details & assumptions

- Availability zones are discovered via AWS data source and the first `availability_zone_count` are used. Ensure your account has the expected AZs.
- If you provide more subnets than AZs, the module assigns subnets sequentially across the AZ list. Adjust inputs or the module if you need different placement logic.
- Route configuration: public route table -> IGW (0.0.0.0/0); private route table -> NAT (0.0.0.0/0).
- Resources may be tagged with the `resource_identifier` where applicable — check resource definitions for exact tag keys.

---

## Testing & development

- Run `terraform init` then `terraform plan` and `terraform apply` in a sandbox AWS account to validate.
- Be mindful of costs for NAT Gateways, Elastic IPs, and CloudWatch Logs retention.
- Destroy resources after testing to avoid continued charges.

---

## Troubleshooting

- "No AZs available" errors: verify region quotas and the `availability_zone_count`.
- Flow logs creation fails: check the IAM role trust/policy and CloudWatch log group names/permissions.
- Private subnets without internet: verify private route table points to a healthy NAT Gateway with an attached EIP.
- NAT Gateway health issues: check NAT Gateway status and EIP association.
- NAT Gateway connectivity issues: verify NAT Gateway subnet routes and security group rules.
