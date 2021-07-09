#
# create Lambda function
#
data "archive_file" "lambda_archive" {
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/${var.lambda_name}-package.zip"
  type        = "zip"
}

locals {
  lambda_archive_md5      = filemd5(data.archive_file.lambda_archive.output_path)
  lambda_package_s3_key   = "lambda/package.zip" # ${var.lambda_name}-
}

/*
resource "aws_s3_bucket_object" "upload_lambda_package_to_s3" {
  bucket            = aws_s3_bucket.lambda_package_bucket.id
  key               = local.lambda_package_s3_key
  source            = data.archive_file.lambda_archive.output_path
  etag              = local.lambda_archive_md5 
}
*/

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.lambda_name 

  role              = aws_iam_role.lambda_exec_role.arn
  memory_size       = 512
  timeout           = 900

  #handler           = "main.lambda_handler"
  #runtime           = "python3.7"

  package_type      = "Image"
  image_uri         = local.ecr_image_url_2 
  publish           = true 

  image_config {
    #entry_point     = [ "/bin/sh", "-c", "/usr/local/bin/python" ]
    #command         = [ "main.lambda_handler" ]
  }

  #s3_bucket         = aws_s3_bucket.lambda_package_bucket.id
  #s3_key            = local.lambda_package_s3_key
  #source_code_hash  = data.archive_file.lambda_archive.output_base64sha256 
  # filebase64sha256("./dist/hello.zip")

  #filename         = data.archive_file.lambda_archive.output_path
  #source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  #depends_on        = [ aws_s3_bucket_object.upload_lambda_package_to_s3 ]
  depends_on        = [ null_resource.docker_build_deploy ]

  environment {
    variables = {
      TF_DATA_DIR   = "/tmp"
    }
  }

  tags             = local.common_tags
}

#
# create cloudwatch log group for lambda
#
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14
}

#
# create Lambda execution IAM role, giving permissions to access other AWS services
#
resource "aws_iam_role" "lambda_exec_role" {
  name                = "${var.app_shortcode}_Lambda_Exec_Role"
  assume_role_policy  = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Action      = [ "sts:AssumeRole" ]
        Principal   = {
            "Service": "lambda.amazonaws.com"
        }
        Effect      = "Allow"
        Sid         = "LambdaAssumeRolePolicy"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.app_shortcode}_Lambda_Policy"
  path        = "/"
  description = "IAM policy with minimum permissions for ${var.lambda_name} Lambda function"

  policy = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Action      = [
          "logs:CreateLogGroup",
        ]
        Resource    = "arn:aws:logs:${var.aws_region}:${local.account_id}:*"
        Effect      = "Allow"
        Sid         = "AllowCloudWatchLogsAccess"
      }, 
      {
        Action      = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource    = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${var.lambda_name}:*"
        Effect      = "Allow"
        Sid         = "AllowCloudWatchPutLogEvents"
      }, 
      {
        Action      = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource    = "arn:aws:s3:::*"
        Effect      = "Allow"
        Sid         = "AllowS3ReadWriteAccessForTfStatefile"
      }, 
      {
        Action      = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource    = "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/*"
        Effect      = "Allow"
        Sid         = "AllowDynamoDBReadWriteAccessForLockfile"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

