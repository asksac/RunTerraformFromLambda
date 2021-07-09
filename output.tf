# define terraform module output values here 

output "lambda_arn" {
  description             = "Lambda ARN"
  value                   = aws_lambda_function.lambda_function.arn
}

output "tf_statefile_bucket" {
  description             = "S3 bucket for storing terraform statefile"
  value                   = aws_s3_bucket.tf_statefile_bucket.id
}

output "tf_lockfile_table" {
  description             = "DynamoDB table for storing terraform lockfile"
  value                   = aws_dynamodb_table.tf_lockfile_table.id
}

/*
output "endpoint_dns" {
  description             = "List of Private DNS entries associated with the Lambda VPC endpoint"
  value                   = aws_vpc_endpoint.lambda_endpoint.dns_entry 
}
*/