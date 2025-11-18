variable "project_name" {
  type        = string
  description = "Project name prefix for resources"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "bucket_expiration_days" {
  type        = number
  default     = 30
  description = "Days to keep artifacts before expiration"
}

variable "github_org" {
  type        = string
  description = "GitHub organization or user name for OIDC trust"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC trust"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider in this AWS account"
  default     = null
}

variable "allowed_aws_principals" {
  type        = list(string)
  default     = []
  description = "Optional list of AWS IAM principal ARNs (roles/users) allowed to assume the CI role (e.g., Jenkins)"
}
