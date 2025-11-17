# ECR Outputs
output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Nombre del repositorio ECR"
  value       = module.ecr.repository_name
}

# Networking Outputs
output "vpc_id" {
  description = "ID de la VPC"
  value       = module.networking.vpc_id
}

output "private_subnets" {
  description = "IDs de las subnets privadas"
  value       = module.networking.private_subnets
}

output "public_subnets" {
  description = "IDs de las subnets públicas"
  value       = module.networking.public_subnets
}

# RDS Aurora Outputs
output "aurora_cluster_endpoint" {
  description = "Endpoint del cluster Aurora"
  value       = module.rds.cluster_endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Endpoint de lectura del cluster Aurora"
  value       = module.rds.cluster_reader_endpoint
}

output "aurora_cluster_id" {
  description = "ID del cluster Aurora"
  value       = module.rds.cluster_id
}

output "aurora_database_name" {
  description = "Nombre de la base de datos"
  value       = module.rds.database_name
}

# Redis Outputs
output "redis_endpoint" {
  description = "Endpoint de Redis"
  value       = module.redis.endpoint
}

output "redis_port" {
  description = "Puerto de Redis"
  value       = module.redis.port
}

# OpenSearch Outputs
output "opensearch_endpoint" {
  description = "Endpoint de OpenSearch"
  value       = module.opensearch.endpoint
}

output "opensearch_kibana_endpoint" {
  description = "Endpoint de OpenSearch Dashboards"
  value       = module.opensearch.dashboards_endpoint
}

output "opensearch_domain_id" {
  description = "ID del dominio OpenSearch"
  value       = module.opensearch.domain_id
}

output "opensearch_arn" {
  description = "ARN del dominio OpenSearch"
  value       = module.opensearch.arn
}

# EKS Outputs
output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = module.eks.cluster_endpoint
}

# CloudFront + S3 Outputs
output "frontend_bucket_name" {
  description = "Nombre del bucket S3 para frontend"
  value       = module.cloudfront.bucket_name
}

output "cloudfront_domain" {
  description = "Dominio de CloudFront"
  value       = module.cloudfront.cloudfront_domain
}

output "cloudfront_url" {
  description = "URL completa del frontend"
  value       = module.cloudfront.cloudfront_url
}

output "cloudfront_id" {
  description = "ID de CloudFront para invalidaciones"
  value       = module.cloudfront.cloudfront_id
}