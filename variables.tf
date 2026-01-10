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

variable "single_nat_gateway" {
  type        = bool
  description = "Flag to indicate if single nat gateway is true"
  default     = false
}

variable "private_subnets" {
  type        = list(any)
  description = "List of cidr blocks for private subnets"
  default     = []
}

variable "region" {
  type        = string
  description = "AWS region where resources are created in"
}

variable "flow_logs" {
  description = "Flow logs settings"
  type = object({
    enabled       = optional(bool)
    log_retention = optional(number)
  })
  default = {
    enabled = false
  }
}

variable "" {

}
