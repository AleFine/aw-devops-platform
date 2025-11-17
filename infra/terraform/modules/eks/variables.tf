variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

variable "private_subnets" {
  type        = list(string)
  description = "Lista de subnets privadas"
}

variable "public_subnets" {
  type        = list(string)
  description = "Lista de subnets públicas"
}

variable "cluster_version" {
  type        = string
  description = "Versión de Kubernetes"
  default     = "1.31" 
}