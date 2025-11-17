variable "project_name" { 
    type = string 
}

variable "environment" { 
    type = string 
}

variable "vpc_id" { 
    type = string 
}

variable "private_subnet_id" { 
    type = string 
}

variable "vpc_cidr_block" { 
    type = string 
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}