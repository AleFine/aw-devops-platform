# Bloque terraform: configuración de versiones y providers requeridos
terraform {
  required_version = ">= 1.0"
  
  # PROVIDERS
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

# Configuración del provider de AWS
provider "aws" {
  region = "us-east-1"
  
  # Tags por defecto
  default_tags {
    tags = {
      Project     = "aw-bootcamp"
      ManagedBy   = "terraform"
      Environment = "learning"
    }
  }
}

# Módulo de VPC de la comunidad
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  # Nombre identificador de la VPC
  name = "aw-bootcamp-vpc"
  
  # Rango CIDR para toda la VPC
  # 10.0.0.0/16 nos da 65,536 direcciones IP (10.0.0.0 a 10.0.255.255)
  cidr = "10.0.0.0/16"
  
  # Zonas de disponibilidad donde crearemos subnets
  # Usamos dos AZs para alta disponibilidad básica
  azs = ["us-east-1a", "us-east-1b"]
  
  # Subnets privadas
  # Cada subnet /24 tiene 256 IPs (251 usables después de las reservadas por AWS)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  
  # Subnets públicas 
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  
  # False para ahorrar costos
  enable_nat_gateway = false
  
  single_nat_gateway = true
  
  # Habilitar DNS en la VPC (necesario para que los nombres de EC2 se resuelvan)
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Tags adicionales específicos para este recurso
  tags = {
    Name = "aw-bootcamp-vpc"
  }
}

# Repositorio ECR para almacenar las imágenes Docker de la aplicación

resource "aws_ecr_repository" "app" {

  name                 = "aw-bootcamp-app"
  image_tag_mutability = "MUTABLE" # Permite sobrescribir tags (útil para 'latest')
  # Escaneo de imágenes para detectar vulnerabilidades

  image_scanning_configuration {

    scan_on_push = true

  }

  # Encriptación de imágenes en reposo
  encryption_configuration {
    encryption_type = "AES256" # Encriptación por defecto de AWS (gratis)
  }

 
  tags = {
    Name = "aw-bootcamp-app-registry"
  }

}

 

# Política de ciclo de vida para limpiar imágenes antiguas y ahorrar costos
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  # Mantener solo las últimas 10 imágenes y eliminar las que tengan más de 30 días

  policy = jsonencode({

    rules = [

      {
        rulePriority = 2
        description  = "Mantener últimas 10 imágenes"
        selection = {

          tagStatus   = "any"

          countType   = "imageCountMoreThan"

          countNumber = 10

        }

        action = {
          type = "expire"
        }
      },

      {

        rulePriority = 1

        description  = "Eliminar imágenes SIN TAG de más de 30 días"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30

        }

        action = {

          type = "expire"

        }

      }

    ]

  })

}


# Outputs: valores que queremos ver después del apply

output "ecr_repository_url" {
  description = "URL del repositorio ECR para la aplicación"
  value       = aws_ecr_repository.app.repository_url

}

output "ecr_repository_name" {
  description = "Nombre del repositorio ECR"
  value       = aws_ecr_repository.app.name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs de las subnets privadas"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs de las subnets públicas"
  value       = module.vpc.public_subnets
}
