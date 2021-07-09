/*

# 
# create a security group for lambda vpc endpoint
# lambda endpoint only require 443 ingress port access
# 
resource "aws_security_group" "lambda_endpoint_sg" {
  name                        = "${var.app_shortcode}_vpc_endpoint_sg"
  vpc_id                      = var.vpc_id

  ingress {
    cidr_blocks               = var.source_cidr_blocks
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
resource "aws_vpc_endpoint" "lambda_endpoint" {
  service_name                = "com.amazonaws.${var.aws_region}.lambda"
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.subnet_ids
  private_dns_enabled         = true

  auto_accept                 = true
  vpc_endpoint_type           = "Interface"

  security_group_ids          = [ aws_security_group.lambda_endpoint_sg.id ]

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

*/