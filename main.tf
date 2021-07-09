/**
 * # Terraform Module - RunTerraformFromLambda
 *
 * This Terraform module builds and deploys a container based Lambda function using 
 * Python source and sample Terraform configuration located inside `src/` directory
 * 
 * ### Usage: 
 * 
 * ```hcl
 * module "lambda_terraform" {
 *   source                 = "./RunTerraformFromLambda"
 * 
 *   app_name               = "RunTerraformFromLambda"
 *   app_shortcode          = "RTFL"
 *   aws_env                = "Dev"
 *   aws_profile            = "default"
 *   aws_region             = "us-east-1"
 *   principal_arn          = "arn:aws:iam::012345678910:role/MyDevOpsRole"
 *   source_cidr_blocks     = [ "200.20.2.0/24" ]
 *   subnet_ids             = [ "subnet-a1b2c3d4", "subnet-e5f6a7b8", "subnet-c9d0e1f2" ]
 *   vpc_id                 = "vpc-f0e1d2c3b4"
 * }
 * ```
 *
 */

data "aws_caller_identity" "current" {}

locals {
  # Common tags to be assigned to all resources
  common_tags             = {
    Application           = var.app_name
    Environment           = var.aws_env
  }

  account_id              = data.aws_caller_identity.current.account_id
}
