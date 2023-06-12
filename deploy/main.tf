terraform {
  backend "s3" {
    bucket         = "recipe-app-api-devops-ikedev"
    key            = "recipe-app.tfstate"
    region         = "us-east-1"
    encrypt        = true # state is encrypted in s3
    dynamodb_table = "recipe-app-api-devops-tf-state-lock"
  }
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 2.54.0"
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}" # dynamically create variables
  common_tags = {
    Environment = terraform.workspace
    Project     = var.project
    Owner       = var.contact
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {} # dont need to assign anything to it