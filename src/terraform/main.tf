## test-module

terraform {
  required_version        = ">= 0.12.0"
  required_providers {
    aws                   = "= 3.11.0"
  }

  backend "s3" {
    bucket                = "rtfl-tf-statefile-229984062599"
    key                   = "test-module"
    region                = "us-east-1" 
    dynamodb_table        = "rtfl-tf-lockfile"
  }
}

output "hello" {
  value = "Hello World"
}
