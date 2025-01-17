terraform {
  backend "s3" {
    bucket = "climate-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  # dynamodb_table = "terraform-lock" 
    encrypt        = true
  }
}