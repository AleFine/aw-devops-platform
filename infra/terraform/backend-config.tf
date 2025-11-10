
terraform {
  backend "s3" {
    bucket         = "aw-bootcamp-tfstate-3102b9bf"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}


