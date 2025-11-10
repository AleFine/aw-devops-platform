
terraform {
  backend "s3" {
    bucket         = "aw-bootcamp-tfstate-79d2cbaa"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}


