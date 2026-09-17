# SSH public key for SSH access (EC2, PROXY)
resource "aws_key_pair" "ssh_key" {
  key_name   = "docbox_ssh_key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name = "docbox-ssh-key"
  }
}

module "docbox" {
  source = "./modules/docbox"

  proxy_host = module.http_proxy.private_ip
  proxy_port = 3128

  instance_name              = "docbox-api-v0_6"
  iam_role_name              = "docbox_role"
  security_group_name        = "docbox-api-sg"
  s3_access_policy_name      = "docbox_s3_access_policy"
  secrets_access_policy_name = "docbox_secrets_access_policy"
  env_secret_name            = "docbox-env-file"

  ssh_key_name = aws_key_pair.ssh_key.key_name

  vpc_id                      = var.vpc_id
  subnet_id                   = aws_subnet.private_subnet.id
  allowed_cidr_blocks         = [aws_subnet.private_subnet.cidr_block]
  full_access_security_groups = [var.vpn_security_group_id]

  additional_policy_arns = {
    "rds"                     = aws_iam_policy.docbox_iam_rds_policy.arn,
    "sqs_read"                = aws_iam_policy.docbox_sqs_read.arn,
    "office_converter_bucket" = module.office_converter_lambda.bucket_access_policy_arn,
    "office_converter_lambda" = module.office_converter_lambda.invoke_policy_arn
  }
}

moved {
  from = aws_instance.api
  to   = module.docbox.aws_instance.api
}

moved {
  from = aws_secretsmanager_secret.docbox_env_secret
  to   = module.docbox.aws_secretsmanager_secret.docbox_env_secret
}

moved {
  from = aws_security_group.docbox_api_sg
  to   = module.docbox.aws_security_group.docbox_api_sg
}

moved {
  from = aws_iam_role.docbox_role
  to   = module.docbox.aws_iam_role.docbox_role
}

moved {
  from = aws_iam_instance_profile.docbox_instance_profile
  to   = module.docbox.aws_iam_instance_profile.docbox_instance_profile
}

moved {
  from = aws_iam_role_policy_attachment.docbox_ssm_core
  to   = module.docbox.aws_iam_role_policy_attachment.docbox_ssm_core
}

moved {
  from = aws_iam_policy.docbox_secrets_manager_policy
  to   = module.docbox.aws_iam_policy.docbox_secrets_manager_policy
}
moved {
  from = aws_iam_role_policy_attachment.additional
  to   = module.docbox.aws_iam_role_policy_attachment.additional
}

moved {
  from = aws_iam_policy.docbox_s3_access_policy
  to   = module.docbox.aws_iam_policy.docbox_s3_access_policy
}

moved {
  from = aws_iam_role_policy_attachment.docbox_s3_access_attachment
  to   = module.docbox.aws_iam_role_policy_attachment.docbox_s3_access_attachment
}

moved {
  from = aws_iam_role_policy_attachment.docbox_iam_rds_policy_attachment
  to   = module.docbox.aws_iam_role_policy_attachment.additional["rds"]
}

moved {
  from = aws_iam_role_policy_attachment.docbox_role_sqs_policy
  to   = module.docbox.aws_iam_role_policy_attachment.additional["sqs_read"]
}

moved {
  from = aws_iam_role_policy_attachment.docbox_role_converter_s3_access
  to   = module.docbox.aws_iam_role_policy_attachment.additional["office_converter_bucket"]
}

moved {
  from = aws_iam_role_policy_attachment.docbox_office_converter_invoke
  to   = module.docbox.aws_iam_role_policy_attachment.additional["office_converter_lambda"]
}

module "http_proxy" {
  source = "./modules/http_proxy"

  instance_name               = "docbox-http-proxy"
  instance_profile_name       = "docbox_proxy_instance_profile"
  iam_role_name               = "docbox_proxy_role"
  security_group_name         = "docbox-http-proxy-sg"
  vpc_id                      = var.vpc_id
  public_subnet_id            = aws_subnet.public_subnet.id
  allowed_cidr_blocks         = [aws_subnet.private_subnet.cidr_block]
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
