data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Docbox API server EC2
#
# This instance will run:
# - The docbox API HTTP server
#
# (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance)
resource "aws_instance" "api" {
  ami           = var.instance_ami
  instance_type = var.instance_type

  subnet_id = var.subnet_id

  # SSH key access
  key_name = var.ssh_key_name

  # Network security group
  vpc_security_group_ids = [aws_security_group.docbox_api_sg.id]

  # Associate IAM role
  iam_instance_profile = aws_iam_instance_profile.docbox_instance_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
  }

  # Disable running prolonged higher CPU speeds at a higher cost
  credit_specification {
    cpu_credits = "standard"
  }

  # Pass proxy details into setup script
  user_data = templatefile("./scripts/ec2-docbox-setup-v0_6.sh", {
    proxy_host  = var.proxy_host
    proxy_port  = tostring(var.proxy_port),
    secret_name = aws_secretsmanager_secret.env_secret.id
  })


  # Prevent replacement due to user_data changes
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = var.instance_name
  }
}

# Create the .env file secret
resource "aws_secretsmanager_secret" "env_secret" {
  name        = var.env_secret_name
  description = ".env file for the docbox server"
}

# Security group for the docbox API EC2 instance
#
# Allows access from the VPN and gateway
resource "aws_security_group" "docbox_api_sg" {
  name        = var.security_group_name
  description = "Security group for the docbox API EC2, allows access from VPN and gateway API"
  vpc_id      = var.vpc_id

  # Allow access through VPN
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.full_access_security_groups
  }

  # Allow access to the API
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
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
    Name = var.security_group_name
  }
}

# Role for the docbox API instance
resource "aws_iam_role" "docbox_role" {
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

# Create instance profile to give the docbox EC2 instance the "docbox" role
resource "aws_iam_instance_profile" "docbox_instance_profile" {
  name = "docbox_instance_profile"
  role = aws_iam_role.docbox_role.name
}


# Associate AmazonSSMManagedInstanceCore to allow the instance to be managed by AWS SSM
resource "aws_iam_role_policy_attachment" "docbox_ssm_core" {
  role       = aws_iam_role.docbox_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "docbox_secrets_manager_policy" {
  name        = var.secrets_access_policy_name
  description = "Allow access to per tenant database and docbox database credentials"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue",
      ],
      Resource = [
        # Typesense credentials
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:typesense/credentials/docbox*",
        # Docbox .env file secret
        aws_secretsmanager_secret.env_secret.arn,
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "docbox_secrets_manager_policy_attachment" {
  role       = aws_iam_role.docbox_role.name
  policy_arn = aws_iam_policy.docbox_secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = var.additional_policy_arns
  role       = aws_iam_role.docbox_role.name
  policy_arn = each.value
}


# IAM Policy that allows the docbox role to perform the following actions on S3 scoped to docbox-* buckets:
# - Upload files
# - Tag uploaded files
# - Get files
# - Delete files
resource "aws_iam_policy" "docbox_s3_access_policy" {
  name        = var.s3_access_policy_name
  description = "Allows S3 access to freely modify any buckets prefixed with docbox- for the docbox EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Object level actions
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::docbox-*/*"
        ]
      }
    ]
  })
}

# Attach the "docbox_secrets_manager_policy" policy to the docbox role
resource "aws_iam_role_policy_attachment" "docbox_s3_access_attachment" {
  role       = aws_iam_role.docbox_role.name
  policy_arn = aws_iam_policy.docbox_s3_access_policy.arn
}
