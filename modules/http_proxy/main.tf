terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.54.0"
    }
  }

  required_version = ">= 1.2.0"
}

resource "aws_instance" "instance" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  # Setup script to install and provision squid
  user_data = file("${path.module}/scripts/setup_amazonLinux2023.sh")

  # Disable running prolonged higher CPU speeds at a higher cost, this
  # feature is not useful for this type of server and would just result
  # in extra costs.
  credit_specification {
    cpu_credits = var.cpu_credits
  }

  tags = {
    Name = var.instance_name
  }
}

# Role for the docbox HTTP proxy
resource "aws_iam_role" "instance_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Create instance profile to give the docbox proxy EC2 instance the "docbox_proxy" role
resource "aws_iam_instance_profile" "instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.instance_role.name
}


# Attach the AmazonSSMManagedInstanceCore policy to allow the instance to be managed by
# AWS SSM
resource "aws_iam_role_policy_attachment" "ssm_core_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "security_group" {
  name        = var.security_group_name
  description = "HTTP proxy security group provides HTTP proxy access to specified CIDR blocks, full outbound access, and full inbound access to specified security groups for VPN access"
  vpc_id      = var.vpc_id

  # Allows HTTP proxy access to specified CIDR blocks
  ingress {
    from_port = 3128
    to_port   = 3128
    protocol  = "tcp"
    # Allow all the private subnets to access the proxy
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow full ingress access to privileged security groups
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.full_access_security_groups
  }

  # Allow full outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
