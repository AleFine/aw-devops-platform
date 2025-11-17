resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  description = "Security group para ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis desde VPC"
    from_port   = 6379
    to_port     = 6379
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

  tags = { Name = "${var.project_name}-redis-sg" }
}

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-redis-subnet"
  description = "Subnet group para ElastiCache Redis"
  subnet_ids  = var.private_subnets

  tags = { Name = "${var.project_name}-redis-subnet-group" }
}

resource "aws_elasticache_parameter_group" "redis" {
  family      = "redis7"
  name        = "${var.project_name}-redis-params"
  description = "Parameter group personalizado para Redis 7.0"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = { Name = "${var.project_name}-redis-params" }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_retention_limit = 0
  snapshot_window          = "03:00-04:00"

  tags = {
    Name        = "${var.project_name}-redis"
    Environment = var.environment
  }
}

output "endpoint" { value = aws_elasticache_cluster.redis.cache_nodes[0].address }
output "port"     { value = aws_elasticache_cluster.redis.port }
