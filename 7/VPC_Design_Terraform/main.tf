# ============================================
# 1. VPC
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "shopnaija-vpc"
    Environment = "production"
    Project     = "ShopNaija"
  }
}

# ============================================
# 2. INTERNET GATEWAY
# ============================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "shopnaija-igw"
  }
}

# ============================================
# 3. ELASTIC IP for NAT Gateway
# ============================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "shopnaija-nat-eip"
  }
}

# ============================================
# 4. PUBLIC SUBNETS (2 AZs)
# ============================================
resource "aws_subnet" "public" {
  count = 2  # Creates 2 subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["172.20.1.0/24", "172.20.2.0/24"][count.index]
  availability_zone = ["af-south-1a", "af-south-1b"][count.index]

  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = {
    Name = "shopnaija-public-${count.index == 0 ? "az1" : "az2"}"
    Type = "public"
  }
}

# ============================================
# 5. PRIVATE SUBNETS - App Tier (2 AZs)
# ============================================
resource "aws_subnet" "private_app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["172.20.10.0/24", "172.20.11.0/24"][count.index]
  availability_zone = ["af-south-1a", "af-south-1b"][count.index]

  tags = {
    Name = "shopnaija-private-app-${count.index == 0 ? "az1" : "az2"}"
    Type = "private-app"
  }
}

# ============================================
# 6. PRIVATE SUBNETS - Database Tier (2 AZs)
# ============================================
resource "aws_subnet" "private_db" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["172.20.20.0/24", "172.20.21.0/24"][count.index]
  availability_zone = ["af-south-1a", "af-south-1b"][count.index]

  tags = {
    Name = "shopnaija-private-db-${count.index == 0 ? "az1" : "az2"}"
    Type = "private-db"
  }
}

# ============================================
# 7. NAT GATEWAY (in public subnet 1)
# ============================================
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Put NAT in first public subnet

  tags = {
    Name = "shopnaija-nat"
  }
}

# ============================================
# 8. PUBLIC ROUTE TABLE
# ============================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "shopnaija-public-rt"
  }
}

# ============================================
# 9. PUBLIC ROUTE (to Internet Gateway)
# ============================================
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ============================================
# 10. PRIVATE ROUTE TABLE (for App tier)
# ============================================
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "shopnaija-private-app-rt"
  }
}

# ============================================
# 11. PRIVATE ROUTE (to NAT Gateway)
# ============================================
resource "aws_route" "private_app_nat" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# ============================================
# 12. PRIVATE ROUTE TABLE (for Database tier)
# ============================================
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "shopnaija-private-db-rt"
  }
}

# ============================================
# 13. PRIVATE ROUTE (to NAT Gateway for DB)
# ============================================
resource "aws_route" "private_db_nat" {
  route_table_id         = aws_route_table.private_db.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# ============================================
# 14. ROUTE TABLE ASSOCIATIONS - Public Subnets
# ============================================
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================
# 15. ROUTE TABLE ASSOCIATIONS - Private App Subnets
# ============================================
resource "aws_route_table_association" "private_app" {
  count = 2

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# ============================================
# 16. ROUTE TABLE ASSOCIATIONS - Private DB Subnets
# ============================================
resource "aws_route_table_association" "private_db" {
  count = 2

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}