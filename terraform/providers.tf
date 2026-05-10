terraform {
  backend "s3" {
    bucket         = "iteso-terraform-state-inaki-99"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
  }
}