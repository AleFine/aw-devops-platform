terraform {
  backend "s3" {
    bucket  = "aw-bootcamp-tfstate-5711d426"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
