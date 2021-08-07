variable "region" {
  description = "AWS region where resources are created"
  type        = string
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
}

variable "resource_identifier" {
  type        = string
  description = "Resource identifier"
  default     = "default"
}

variable "public_subnets" {
  type        = list(any)
  description = "List of CIDR blocks assigned to public subnets"
}

variable "availability_zone_count" {
  type        = number
  description = "Number of availability zones to setup"
  default     = 1
}
