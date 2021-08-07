locals {
  tags = {
    created_by = "terraform"
  }

  azs = slice(data.aws_availability_zones.azs,
    0,
    var.availability_zone_count
  )
}
