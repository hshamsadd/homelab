terraform {
  # Required Terraform Version
  required_version = "~> 1.14.0"

  # Required Provider Version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = ""
}

# Create a VPC
resource "aws_vpc" "name" {
  cidr_block = "10.0.0.0/16"

}