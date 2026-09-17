
# Secret to store the environment variables in
output "env_secret_name" {
  value = aws_secretsmanager_secret.env_secret.name
}

output "role_id" {
  value = aws_iam_role.docbox_role.id
}

output "role_arn" {
  value = aws_iam_role.docbox_role.arn
}

output "api_sg_id" {
  value = aws_security_group.docbox_api_sg.id
}

output "api_instance_id" {
  value = aws_instance.api.id
}

output "private_ip" {
  value = aws_instance.api.private_ip
}
