variable "repository_name" {
  type        = string
  description = "Nombre del repositorio ECR"
}

variable "scan_on_push" {
  type        = bool
  description = "Habilitar escaneo de vulnerabilidades al push"
  default     = true
}

variable "retain_last" {
  type        = number
  description = "Cantidad de imágenes a mantener"
  default     = 10
}

variable "expire_untagged_days" {
  type        = number
  description = "Días para expirar imágenes sin tag"
  default     = 30
}
