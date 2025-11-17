module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.8.0"

  name               = "${var.project_name}-eks"
  kubernetes_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  # Habilitar acceso público para facilitar la administración
  endpoint_public_access = true
  
  # Permitir que el creador del cluster tenga permisos de administrador
  enable_cluster_creator_admin_permissions = true

  # Configurar los cluster addons ANTES de crear los nodos
  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true  # Instalar ANTES de crear los nodos
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true  # Instalar ANTES de crear los nodos
      configuration_values = jsonencode({
        env = {
          # Habilitar delegación de prefijos para más IPs por nodo
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Configuración de los node groups
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"  # Amazon Linux 2023
      instance_types = ["t3.medium"]
      
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Habilitar acceso a Internet para descargar imágenes
      # Los nodos en subnets privadas usan NAT Gateway
      
      # Etiquetas para organización
      labels = {
        Environment = "dev"
        ManagedBy   = "terraform"
      }
      
      # Configuración de disco
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

# Outputs
output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Nombre del cluster EKS"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint del cluster EKS"
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Security group del cluster"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN del OIDC provider para IRSA"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Certificado del cluster"
  sensitive   = true
}