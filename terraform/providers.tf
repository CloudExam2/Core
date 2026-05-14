terraform {
  backend "s3" {
    bucket = "iteso-terraform-state-inaki-99"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }


  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 3. THE SETTINGS: Configures the specific details for those providers
provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = var.github_token # Uses the GH_PAT secret you just set up
  owner = "CloudExam2"     # Ensures it builds secrets in your organization
}