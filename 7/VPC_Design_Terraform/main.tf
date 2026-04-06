module "shopnaija_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "shopnaija-vpc"
  cidr = "172.20.0.0/16"

  azs             = ["af-south-1a", "af-south-1b"]
  public_subnets  = ["172.20.1.0/24", "172.20.2.0/24"]
  private_subnets = ["172.20.10.0/24", "172.20.11.0/24"]
  database_subnets = ["172.20.20.0/24", "172.20.21.0/24"]

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = true   

  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for organization
  tags = {
    Environment = "production"
    Project     = "ShopNaija"
    ManagedBy   = "Terraform"
  }
}