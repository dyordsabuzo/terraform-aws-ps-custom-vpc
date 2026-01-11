output "vpc_id" {
  description = "The ID of the VPC"
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  description = "The IDs of the public subnets"
  value = aws_subnet.public_subnet.*.id
}

output "private_subnets" {
  description = "The IDs of the private subnets"
  value = aws_subnet.private_subnet.*.id
}
