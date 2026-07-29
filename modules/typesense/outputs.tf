
output "api_key" {
  value     = random_password.api_key.result
  sensitive = true
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "instance_id" {
  value = aws_instance.instance.id
}

output "instance_arn" {
  value = aws_instance.instance.arn
}
