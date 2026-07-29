# Security group for the docbox API EC2 instance
#
# Allows access from the VPN and gateway
resource "aws_security_group" "docbox_api_sg" {
  name        = "docbox-api-sg"
  description = "Security group for the docbox API EC2, allows access from VPN and gateway API"
  vpc_id      = var.vpc_id

  # Allow access through VPN
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.vpn_security_group_id]
  }

  # Allow access to the API
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow ingres from 443 on the private subnet, used by AWS Secrets manager
  # requests to the secrets manager will timeout without this
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docbox-api-sg"
  }
}
