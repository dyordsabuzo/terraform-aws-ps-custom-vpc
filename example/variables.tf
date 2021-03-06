variable "region" {
  type        = string
  description = "AWS region where resources will be created in"
  default     = "ap-southeast-2"
}

variable "resource_identifier" {
  type = string
  description = "Resource identifier"
}