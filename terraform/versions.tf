terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local state for v1. Switch to S3 + DynamoDB lock once the
  # deployment stabilizes; example below.
  #
  # backend "s3" {
  #   bucket         = "go-terraform-state"
  #   key            = "go-jupyter/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "go-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}
