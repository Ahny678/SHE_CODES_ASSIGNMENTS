output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.shopnaija_vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.shopnaija_vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.shopnaija_vpc.private_subnets
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.shopnaija_vpc.database_subnets
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.shopnaija_vpc.natgw_ids
}