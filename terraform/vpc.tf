# ==============================================================================
# vpc.tf - Creates isolated networking: VPC, Subnets, IGW, Route Table
# - Ensures EC2 instances are in a public network with internet access
# - Includes 2 subnets in different AZs to satisfy AWS Load Balancer HA requirements
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

# ==============================================================================
# Primary Public Subnet (Availability Zone A)
# ==============================================================================
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Critical for public IP assignment

  tags = {
    Name = "${var.project_prefix}-public-subnet-a"
  }
}

# ==============================================================================
# Secondary Public Subnet (Availability Zone B) - Required for ALB
# ==============================================================================
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-public-subnet-b"
  }
}

# ==============================================================================
# Route Table for Public Subnets
# ==============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_prefix}-rt-public"
  }
}

# ==============================================================================
# Associate Route Table with Subnets
# ==============================================================================
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}