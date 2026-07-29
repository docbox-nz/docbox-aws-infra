# SSH public key for SSH access (EC2, PROXY)
resource "aws_key_pair" "ssh_key" {
  key_name   = "docbox_ssh_key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name = "docbox-ssh-key"
  }
}

# Docbox API server EC2
#
# This instance will run:
# - The docbox API HTTP server
#
# (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance)
resource "aws_instance" "api" {
  # Amazon Linux 2023 AMI 2023.10.20260105.0 arm64 HVM kernel-6.1
  ami           = "ami-0727d44a1158304d8"
  instance_type = var.api_instance_type

  subnet_id = aws_subnet.private_subnet.id

  # SSH key access
  key_name = aws_key_pair.ssh_key.key_name

  # Network security group
  vpc_security_group_ids = [aws_security_group.docbox_api_sg.id]

  # Associate IAM role
  iam_instance_profile = aws_iam_instance_profile.docbox_instance_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  # Disable running prolonged higher CPU speeds at a higher cost
  credit_specification {
    cpu_credits = "standard"
  }

  # Pass proxy details into setup script
  user_data = templatefile("./scripts/ec2-docbox-setup-v0_6.sh", {
    proxy_host  = module.http_proxy.private_ip
    proxy_port  = "3128"
    secret_name = aws_secretsmanager_secret.docbox_env_secret.id
  })


  # API must wait for the HTTP proxy to be fully initialized before
  # it can run so that it can use the HTTP proxy to install dependencies
  # (As it does not have regular network access since its in a private subnet)
  depends_on = [module.http_proxy]

  # Prevent replacement due to user_data changes
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "docbox-api-v0_6"
  }
}



module "http_proxy" {
  source = "./modules/http_proxy"

  instance_name         = "docbox-http-proxy"
  instance_profile_name = "docbox_proxy_instance_profile"
  iam_role_name         = "docbox_proxy_role"
  security_group_name   = "docbox-http-proxy-sg"
  vpc_id                = var.vpc_id
  public_subnet_id      = aws_subnet.public_subnet.id
  allowed_cidr_blocks = [
    aws_subnet.private_subnet.cidr_block,
  ]
  full_access_security_groups = [var.vpn_security_group_id]
}

moved {
  from = aws_instance.http_proxy
  to   = module.http_proxy.aws_instance.instance
}

moved {
  from = aws_iam_instance_profile.docbox_proxy_instance_profile
  to   = module.http_proxy.aws_iam_instance_profile.instance_profile
}

moved {
  from = aws_iam_role.docbox_proxy_role
  to   = module.http_proxy.aws_iam_role.instance_role
}

moved {
  from = aws_iam_role_policy_attachment.docbox_proxy_ssm_core
  to   = module.http_proxy.aws_iam_role_policy_attachment.ssm_core_attachment
}

moved {
  from = aws_security_group.http_proxy_sg
  to   = module.http_proxy.aws_security_group.security_group
}

module "typesense" {
  source = "./modules/typesense"

  proxy_host = module.http_proxy.private_ip
  proxy_port = 3128

  instance_name         = "docbox-typesense"
  instance_role_name    = "docbox_typesense_role"
  instance_profile_name = "docbox_typesense_instance_profile"
  security_group_name   = "docbox-typesense"

  ssh_key_name = aws_key_pair.ssh_key.key_name

  vpc_id    = var.vpc_id
  subnet_id = aws_subnet.private_subnet.id
  allowed_cidr_blocks = [
    aws_subnet.private_subnet.cidr_block,
  ]
  full_access_security_groups = [var.vpn_security_group_id]
}

moved {
  from = random_password.typesense_api_key
  to   = module.typesense.random_password.api_key
}

moved {
  from = aws_instance.docbox_typesense
  to   = module.typesense.aws_instance.instance
}

moved {
  from = aws_iam_role.docbox_typesense_role
  to   = module.typesense.aws_iam_role.instance_role
}

moved {
  from = aws_iam_instance_profile.docbox_typesense_instance_profile
  to   = module.typesense.aws_iam_instance_profile.instance_profile
}

moved {
  from = aws_iam_role_policy_attachment.docbox_typesense_ssm_core
  to   = module.typesense.aws_iam_role_policy_attachment.ssm_core_attachment
}

moved {
  from = aws_security_group.docbox_typesense_sg
  to   = module.typesense.aws_security_group.security_group
}
