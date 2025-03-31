terraform {
  backend "s3" {
    bucket = "core-terraform-state-20250330221812"
    key            = "terraform/infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "core-terraform-locks-20250330221812"
    encrypt        = true
  }
}