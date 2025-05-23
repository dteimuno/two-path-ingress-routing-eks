terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
  backend "s3" {
    bucket = "eks-backend-dtm"
    key    = "backend2.hcl"
    region = "us-east-1"
  }
  required_version = ">= 1.0.0"
}