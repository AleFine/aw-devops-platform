resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket de S3 para almacenar el estado de Terraform
resource "aws_s3_bucket" "tfstate" {
  bucket = "aw-bootcamp-tfstate-${random_id.bucket_suffix.hex}"
  
  # Prevenir eliminación accidental del bucket (importante para seguridad)
  lifecycle {
     # prevent_destroy = true --produccion 
    prevent_destroy = false 
  }
  
  tags = {
    Name        = "Terraform State Bucket"
    Description = "Almacena el estado de Terraform de forma remota y segura"
  }
}

# Habilitar versionado en el bucket
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Habilitar cifrado en reposo
# Todo el contenido del bucket será cifrado automáticamente
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acceso público al bucket
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output del nombre del bucket para referencia
output "tfstate_bucket_name" {
  description = "Nombre del bucket de S3 para el estado de Terraform"
  value       = aws_s3_bucket.tfstate.bucket
}
