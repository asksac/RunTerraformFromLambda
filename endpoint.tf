# 
# create a security group for lambda vpc endpoint
# lambda endpoint only require 443 ingress port access
# 
resource "aws_security_group" "lambda_endpoint_sg" {
  name                        = "${var.app_shortcode}_lambda_endpoint_sg"
  vpc_id                      = data.aws_vpc.given.id

  ingress {
    cidr_blocks               = var.source_cidr_blocks
    from_port                 = 443
    to_port                   = 443
    protocol                  = "tcp"
  }

  tags                        = local.common_tags
}

# 
# create a common security group for multiple other vpc endpoints
# such as cloudwatch logs, dynamodb, s3, and ecr
# 
resource "aws_security_group" "common_endpoint_sg" {
  name                        = "${var.app_shortcode}_common_endpoint_sg"
  vpc_id                      = data.aws_vpc.given.id

  ingress {
    cidr_blocks               = data.aws_vpc.given.cidr_block_associations.*.cidr_block
    from_port                 = 443
    to_port                   = 443
    protocol                  = "tcp"
  }

  tags                        = local.common_tags
}

#
# create a vpc endpoint for lambda and deploy in specified subnets
# restrict access granted through this endpoint to only lambda:InvokeFunction call
#
resource "aws_vpc_endpoint" "vpce_lambda" {
  service_name                = "com.amazonaws.${var.aws_region}.lambda"
  vpc_id                      = data.aws_vpc.given.id
  subnet_ids                  = data.aws_subnet.given[*].id
  private_dns_enabled         = true

  auto_accept                 = true
  vpc_endpoint_type           = "Interface"

  security_group_ids          = [ aws_security_group.lambda_endpoint_sg.id, aws_security_group.common_endpoint_sg.id ]

  policy = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Principal   = {
          AWS       = var.principal_arn
        }
        Action      = [ "lambda:InvokeFunction" ]
        Resource    = [ aws_lambda_function.lambda_function.arn ]
        Effect      = "Allow"
        Sid         = "AllowLambdaInvokeFunctionOnly"
      }
    ]
  })

  tags                        = merge(local.common_tags, map("Name", "${var.app_shortcode}_lambda_endpoint"))
}

resource "aws_vpc_endpoint" "vpce_cwlogs" {
  service_name          = "com.amazonaws.${var.aws_region}.logs"
  vpc_id                = data.aws_vpc.given.id
  subnet_ids            = data.aws_subnet.given[*].id
  private_dns_enabled   = true

  auto_accept           = true
  vpc_endpoint_type     = "Interface"

  security_group_ids    = [ aws_security_group.common_endpoint_sg.id ]

  policy                = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "SSMRequiredPermissions"
        Principal = "*"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]        
  })

  tags                  = merge(
    local.common_tags, 
    map("Name", "${var.app_shortcode}_cw_logs")
  )
}

resource "aws_vpc_endpoint" "vpce_s3" {
  service_name          = "com.amazonaws.${var.aws_region}.s3"
  vpc_id                = data.aws_vpc.given.id
  route_table_ids       = data.aws_route_table.subnet_rt[*].id
  private_dns_enabled   = true

  auto_accept           = true
  vpc_endpoint_type     = "Gateway"

  security_group_ids    = [ aws_security_group.common_endpoint_sg.id ]

  policy                = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "FullS3Access"
        Principal = "*"
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::*"
      },
    ]        
  })

  tags                  = merge(
    local.common_tags, 
    map("Name", "${var.app_shortcode}_s3")
  )
}

resource "aws_vpc_endpoint" "vpce_ecr_dkr" {
  service_name          = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_id                = data.aws_vpc.given.id
  subnet_ids            = data.aws_subnet.given[*].id
  private_dns_enabled   = true

  auto_accept           = true
  vpc_endpoint_type     = "Interface"

  security_group_ids    = [ aws_security_group.common_endpoint_sg.id ]

  policy                = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "FullAccess"
        Principal = "*"
        Action = [
          "*",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]        
  })

  tags                  = merge(
    local.common_tags, 
    map("Name", "${var.app_shortcode}_ecr_dkr")
  )
}

resource "aws_vpc_endpoint" "vpce_ecr_api" {
  service_name          = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_id                = data.aws_vpc.given.id
  subnet_ids            = data.aws_subnet.given[*].id
  private_dns_enabled   = true

  auto_accept           = true
  vpc_endpoint_type     = "Interface"

  security_group_ids    = [ aws_security_group.common_endpoint_sg.id ]

  policy                = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "FullAccess"
        Principal = "*"
        Action = [
          "*",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]        
  })

  tags                  = merge(
    local.common_tags, 
    map("Name", "${var.app_shortcode}_ecr_api")
  )
}


/*
# vpc endpoints to ecr (docker, api and s3) are required for fargate tasks to pull container image
resource "aws_vpc_endpoint" "vpce_ecr_dkr" {
  service_name                = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_id                      = aws_vpc.vpc2.id
  subnet_ids                  = [ aws_subnet.vpc2_subnet_priv1.id, aws_subnet.vpc2_subnet_priv2.id ]
  private_dns_enabled         = true

  auto_accept                 = true
  vpc_endpoint_type           = "Interface"

  security_group_ids          = [ aws_security_group.ecr_vpce_sg.id ]
  tags                        = merge(local.common_tags, map("Name", "${var.app_shortcode}_ecr_dkr_endpoint"))
}

resource "aws_vpc_endpoint" "vpce_ecr_api" {
  service_name                = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_id                      = aws_vpc.vpc2.id
  subnet_ids                  = [ aws_subnet.vpc2_subnet_priv1.id, aws_subnet.vpc2_subnet_priv2.id ]
  private_dns_enabled         = true

  auto_accept                 = true
  vpc_endpoint_type           = "Interface"

  security_group_ids          = [ aws_security_group.ecr_vpce_sg.id ]
  tags                        = merge(local.common_tags, map("Name", "${var.app_shortcode}_ecr_api_endpoint"))
}

}
*/