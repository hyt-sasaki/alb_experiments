locals {
  app_name = "experiment"
}

####################################################
# VPC
####################################################

resource "aws_vpc" "this" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = local.app_name
  }
}

####################################################
# Public Subnet
####################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = local.app_name
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${local.app_name}-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${local.app_name}-public-1c"
  }
}

####################################################
# Private Subnet
####################################################

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${local.app_name}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "192.168.20.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${local.app_name}-private-1c"
  }
}


# ####################################################
# # Elastic IP for nat
# ####################################################
# resource "aws_eip" "nat_1a" {
#   vpc = true
#   tags = {
#     Name = "${local.app_name}-eip-for-natgw-1a"
#   }
# }
# ####################################################
# # NAT Gateway
# ####################################################
# resource "aws_nat_gateway" "nat_1a" {
#   subnet_id = aws_subnet.public_1a.id
#   allocation_id = aws_eip.nat_1a.id
#   tags = {
#     Name = "${local.app_name}-natgw-1a"
#   }
# }
####################################################
# Public Subnet Route Table
####################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "${local.app_name}-public"
  }
}
####################################################
# Public Route Table Association
####################################################

resource "aws_route_table_association" "public_1a_to_ig" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c_to_ig" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

####################################################
# Private Subnet Route Table
####################################################
# resource "aws_route_table" "private_1a" {
#   vpc_id = aws_vpc.this.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_1a.id
#   }
#   tags = {
#     Name = "${local.app_name}-private-1a"
#   }
# }

####################################################
# Private Route Table Association
####################################################
# resource "aws_route_table_association" "private_1a" {
#   route_table_id = aws_route_table.private_1a.id
#   subnet_id = aws_subnet.private_1a.id
# }
