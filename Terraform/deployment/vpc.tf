resource "aws_vpc" "vpc_ecs" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw_ecs" {
  vpc_id = aws_vpc.vpc_ecs.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public_subnet_ecs" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.vpc_ecs.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private_subnet_ecs" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.vpc_ecs.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
  })
}

resource "aws_eip" "e_nat_ecs" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat_ecs" {
  allocation_id = aws_eip.e_nat_ecs.id
  subnet_id     = aws_subnet.public_subnet_ecs[0].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.igw_ecs]
}

resource "aws_route_table" "rt_public_ecs" {
  vpc_id = aws_vpc.vpc_ecs.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route" "route_public_ecs" {
  route_table_id         = aws_route_table.rt_public_ecs.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_ecs.id
}

resource "aws_route_table_association" "rta_public_ecs" {
  count = length(aws_subnet.public_subnet_ecs)

  subnet_id      = aws_subnet.public_subnet_ecs[count.index].id
  route_table_id = aws_route_table.rt_public_ecs.id
}

resource "aws_route_table" "rt_private_ecs" {
  vpc_id = aws_vpc.vpc_ecs.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

resource "aws_route" "route_private_ecs" {
  route_table_id         = aws_route_table.rt_private_ecs.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_ecs.id
}

resource "aws_route_table_association" "rta_private_ecs" {
  count = length(aws_subnet.private_subnet_ecs)

  subnet_id      = aws_subnet.private_subnet_ecs[count.index].id
  route_table_id = aws_route_table.rt_private_ecs.id
}