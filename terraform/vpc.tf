# Shared VPC for services (Catalog, future Sales, etc.). Default VPC is not used.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "exam-core-vpc"
  }
}

# --- Internet Gateway (disabled for student lab: no generic public internet path) ---
# Re-enable the block below AND the default route in aws_route_table.public if you need
# browser/SSH to the instance's public IPv4 from the open internet.
#
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "exam-core-igw"
#   }
# }

# Subnets used by RDS (two AZs) and by interface endpoints / EC2 (see vpc_endpoints.tf).
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "exam-core-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "exam-core-public-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # With no 0.0.0.0/0 route, traffic stays inside the VPC (+ AWS via interface endpoints).
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.main.id
  # }

  tags = {
    Name = "exam-core-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
