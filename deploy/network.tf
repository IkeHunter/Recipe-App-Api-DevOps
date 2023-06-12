resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16" # allows ip addresses, /16 indicates amount of hosts/addresses allowed
  enable_dns_support   = true
  enable_dns_hostnames = true # allows custom hostnames

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-vpc")
  )
}

resource "aws_internet_gateway" "main" { # main frontdoor
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-main")
  )
}