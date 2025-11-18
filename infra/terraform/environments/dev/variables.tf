variable "project_name" {
  type    = string
  default = "aw-bootcamp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_version" {
  type        = string
  description = "Versión de Kubernetes para EKS"
  default     = "1.31"
}

# DB
variable "db_username" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "awbootcamp"
}

# CI/OIDC
variable "github_org" {
  type    = string
  default = "AleFine"
}

variable "github_repo" {
  type    = string
  default = "aw-devops-platform"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN del OIDC provider de GitHub en esta cuenta (si omites, se derivará)."
  default     = null
}