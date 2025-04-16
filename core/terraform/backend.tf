terraform {
  backend "s3" {
    bucket = "core-terraform-state-20250415210350"
    key            = "terraform/infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "core-terraform-locks-20250415210350"
    encrypt        = true
  }
}