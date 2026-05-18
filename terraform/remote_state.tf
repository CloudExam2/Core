# Live EC2 ids from Catalog/Sales terraform (source of truth for the metrics dashboard).

data "terraform_remote_state" "catalog" {
  backend = "s3"

  config = {
    bucket = "iteso-terraform-state-inaki-69"
    key    = "catalog/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "sales" {
  backend = "s3"

  config = {
    bucket = "iteso-terraform-state-inaki-69"
    key    = "sales/terraform.tfstate"
    region = "us-east-1"
  }
}
