terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Optional: Remote state storage in S3
  # Uncomment and configure when ready for team collaboration
  # backend "s3" {
  #   bucket = "chatter-terraform-state"
  #   key    = "prod/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Chatter"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
