output "repository_url" {
  description = "URL completa del repositorio ECR"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Nombre del repositorio ECR"
  value       = aws_ecr_repository.this.name
}
