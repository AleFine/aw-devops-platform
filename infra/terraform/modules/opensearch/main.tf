resource "aws_security_group" "opensearch" {
  name_prefix = "${var.project_name}-os-"
  description = "Security group para OpenSearch"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS desde VPC"
    from_port   = 443
    to_port     = 443
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

  tags = { Name = "${var.project_name}-opensearch-sg" }
}

resource "aws_kms_key" "opensearch" {
  description             = "KMS key para cifrado de OpenSearch"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = { Name = "${var.project_name}-opensearch-kms" }
}

resource "aws_kms_alias" "opensearch" {
  name          = "alias/${var.project_name}-opensearch"
  target_key_id = aws_kms_key.opensearch.key_id
}

resource "aws_cloudwatch_log_group" "opensearch_app" {
  name              = "/aws/opensearch/${var.project_name}/application"
  retention_in_days = 7
  tags = { Name = "${var.project_name}-opensearch-app-logs" }
}

resource "aws_cloudwatch_log_group" "opensearch_search" {
  name              = "/aws/opensearch/${var.project_name}/search"
  retention_in_days = 7
  tags = { Name = "${var.project_name}-opensearch-search-logs" }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${var.project_name}-opensearch-logs"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "es.amazonaws.com" }
      Action   = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource = "arn:aws:logs:*"
    }]
  })
}

resource "aws_opensearch_domain" "this" {
  domain_name    = "${var.project_name}-os"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = "t3.small.search"
    instance_count         = 1
    zone_awareness_enabled = false
    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
    iops        = 3000
    throughput  = 125
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_id]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.opensearch.arn
  }
  node_to_node_encryption { enabled = true }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "es:*"
        Resource = "arn:aws:es:${var.region}:${var.account_id}:domain/${var.project_name}-os/*"
      }
    ]
  })

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "false"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_app.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_search.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  snapshot_options { automated_snapshot_start_hour = 3 }

  tags = {
    Name        = "${var.project_name}-opensearch"
    Environment = var.environment
  }
}

output "endpoint" { value = "https://${aws_opensearch_domain.this.endpoint}" }
output "dashboards_endpoint" { value = "https://${aws_opensearch_domain.this.endpoint}/_dashboards" }
output "domain_id" { value = aws_opensearch_domain.this.domain_id }
output "arn" { value = aws_opensearch_domain.this.arn }
