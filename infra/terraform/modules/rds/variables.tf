variable "project_name" { 
	type = string 
}
variable "environment" { 
	type = string 
}
variable "vpc_id" { 
	type = string 
}
variable "vpc_cidr_block" { 
	type = string 
}
variable "private_subnets" { 
	type = list(string) 
}

variable "db_username" {
	type      = string
	sensitive = true
}
variable "db_password" {
	type      = string
	sensitive = true
}
variable "db_name" { 
	type = string 
}

variable "engine_version" {
	type    = string
	default = "8.0.mysql_aurora.3.04.0"
}
variable "instance_class" {
	type    = string
	default = "db.t3.medium"
}
