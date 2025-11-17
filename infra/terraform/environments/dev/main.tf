data "aws_caller_identity" "current" {}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

#Random ID para nombres únicos
resource "random_id" "suffix" {
  byte_length = 4
}

# Variables Locales
locals {
  project_name = var.project_name

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Networking (VPC)
module "networking" {
  source = "../../modules/networking"

  project_name    = var.project_name
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}

# ECR
module "ecr" {
  source = "../../modules/ecr"

  repository_name      = "aw-bootcamp-app"
  retain_last          = 10
  expire_untagged_days = 30
}

# RDS Aurora MySQL
module "rds" {
  source = "../../modules/rds"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  vpc_cidr_block  = module.networking.vpc_cidr_block
  private_subnets = module.networking.private_subnets
  db_username     = var.db_username
  db_password     = var.db_password
  db_name         = var.db_name
}

# Redis
module "redis" {
  source = "../../modules/redis"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  vpc_cidr_block  = module.networking.vpc_cidr_block
  private_subnets = module.networking.private_subnets
}

# OpenSearch
module "opensearch" {
  source = "../../modules/opensearch"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnet_id = module.networking.private_subnets[0]
  vpc_cidr_block    = module.networking.vpc_cidr_block

  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

# EKS Cluster
module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  cluster_version = var.cluster_version
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnets
  public_subnets  = module.networking.public_subnets
}

# CloudFront + S3 Frontend
# ============================================

module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name = local.project_name
  bucket_name  = "aw-bootcamp-frontend-${random_id.suffix.hex}"
  price_class  = "PriceClass_100"

  tags = local.common_tags
}

