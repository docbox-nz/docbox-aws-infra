terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.54.0"
    }
  }

  required_version = ">= 1.2.0"
}

# Generate a random API key for Typesense
resource "random_password" "api_key" {
  length  = 48
  special = false
}

# Typesense
#
# Search index server instance
resource "aws_instance" "instance" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Network security group
  vpc_security_group_ids = [aws_security_group.security_group.id]

  # SSH key access
  key_name = var.ssh_key_name

  # Associate IAM role
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  # Pass proxy details into setup script
  user_data = templatefile("${path.module}/scripts/setup.sh", {
    proxy_host        = var.proxy_host
    proxy_port        = tostring(var.proxy_port),
    typesense_api_key = random_password.api_key.result
  })

  # Disable running prolonged higher CPU speeds at a higher cost
  credit_specification {
    cpu_credits = "standard"
  }

  # Prevent replacement due to user_data changes
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = var.instance_name
  }
}

# Role for the docbox typesense instance
resource "aws_iam_role" "instance_role" {
  name = var.instance_role_name

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

# Create instance profile to give the docbox typesense EC2 instance the "docbox_typesense" role
resource "aws_iam_instance_profile" "instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.instance_role.name
}


# Associate AmazonSSMManagedInstanceCore to allow the instance to be managed by AWS SSM
resource "aws_iam_role_policy_attachment" "ssm_core_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

locals {
  # Port that the typesense service uses
  typesense_port = 8108
}

# Security group for the typesense server
resource "aws_security_group" "security_group" {
  name        = var.security_group_name
  description = "Security group for typesense"
  vpc_id      = var.vpc_id

  # Allows typesense access to specified CIDR blocks
  ingress {
    from_port   = local.typesense_port
    to_port     = local.typesense_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Access from private subnet services"
  }

  # Allow full ingress access to privileged security groups
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.full_access_security_groups
    description     = "Full access security groups"
  }

  # Allow full outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
