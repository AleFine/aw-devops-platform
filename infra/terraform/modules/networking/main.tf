module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = "${var.project_name}-vpc"
  cidr = var.cidr
  azs  = var.azs

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID de la VPC"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "IDs de subnets privadas"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "IDs de subnets públicas"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR de la VPC"
}
