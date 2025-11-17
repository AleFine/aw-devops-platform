variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket S3 (debe ser único globalmente)"
  type        = string
}

variable "price_class" {
  description = "Price class de CloudFront"
  type        = string
  default     = "PriceClass_100"  # Solo NA y Europa para ahorrar costos
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}