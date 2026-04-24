# ============================================================
# vpc.tf
# ------------------------------------------------------------
# PURPOSE:
#   Creates the complete networking layer for this project.
#
# WHY TWO SUBNETS?
#   AWS ALB requires at least 2 subnets in 2 different
#   Availability Zones. All EC2 instances live in subnet_1.
#   Subnet_2 exists only to satisfy the ALB requirement.
# ============================================================


# -------------------------------------------------------
# 1. VPC — the isolated private network
# -------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 2. Public Subnet 1 — ap-southeast-1a
#    All 5 EC2 instances are launched in this subnet
# -------------------------------------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1a"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 3. Public Subnet 2 — ap-southeast-1b
#    Only used by the ALB — no EC2 instances here
# -------------------------------------------------------
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1b"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 4. Internet Gateway — connects VPC to the internet
# -------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 5. Route Table — sends all traffic to internet gateway
# -------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 6. Route Table Associations
#    Both subnets must use the public route table
#    so instances and the ALB can reach the internet
# -------------------------------------------------------
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
