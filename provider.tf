terraform {
  required_version        = ">= 0.12.24"
  required_providers {
    aws                   = ">= 3.11.0"
    archive               = "~> 2.0.0"
    null                  = "~> 3.0.0"
  }
}

provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region
}

