# SG para Aurora
resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-"
  description = "Security group para Aurora MySQL cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL desde VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Permitir todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-aurora-sg"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-"
  description = "Subnet group para Aurora MySQL"
  subnet_ids  = var.private_subnets

  tags = {
    Name = "${var.project_name}-aurora-subnet-group"
  }
}

resource "aws_kms_key" "rds" {
  description             = "KMS key para cifrado de RDS"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${var.project_name}-rds-kms" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${var.project_name}-rds-mon-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-rds-monitoring-role" }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.16.1"

  name           = "${var.project_name}-db"
  engine         = "aurora-mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class
  instances      = { one = {} }

  vpc_id                 = var.vpc_id
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  master_username = var.db_username
  master_password = var.db_password
  database_name   = var.db_name

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  backup_retention_period      = 1
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  skip_final_snapshot          = true

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  cluster_monitoring_interval     = 60
  create_monitoring_role          = false
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled = false
  deletion_protection          = false
  apply_immediately            = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

output "cluster_endpoint" {
  value       = module.aurora.cluster_endpoint
  description = "Endpoint del cluster para escritura"
}

output "cluster_reader_endpoint" {
  value       = module.aurora.cluster_reader_endpoint
  description = "Endpoint del cluster para lectura"
}

output "cluster_id" {
  value       = module.aurora.cluster_id
  description = "ID del cluster"
}

output "database_name" {
  value       = module.aurora.cluster_database_name
  description = "Nombre de la base de datos"
}
