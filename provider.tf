# Configure the Terraform version and required providers
terraform {
  required_providers {
    aws = {
      # Use the official AWS provider from HashiCorp
      source = "hashicorp/aws"
      # Require a version in the 6.x range
      version = "~> 6.0"
    }
  }
}

# Configure the AWS provider with the specified region
provider "aws" {
  region = var.aws_region
}
