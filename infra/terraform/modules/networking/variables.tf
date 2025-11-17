variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "cidr" {
  type        = string
  description = "CIDR principal de la VPC"
}

variable "azs" {
  type        = list(string)
  description = "Lista de Availability Zones"
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnets privadas"
}

variable "public_subnets" {
  type        = list(string)
  description = "Subnets públicas"
}
