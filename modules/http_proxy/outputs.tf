output "instance_id" {
  value = aws_instance.instance.id
}

output "instance_arn" {
  value = aws_instance.instance.arn
}

output "role_arn" {
  value = aws_iam_role.instance_role.arn
}

output "role_name" {
  value = aws_iam_role.instance_role.name
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}

output "security_group_arn" {
  value = aws_security_group.security_group.arn
}
