

# Get private IP of API EC2 instance for SSH
output "api_private_ip" {
  value = aws_instance.api.private_ip
}

output "converter_private_ip" {
  value = aws_instance.converter_api.private_ip
}

# Generated instance ID for the API EC2 instance 
output "api_instance_id" {
  value = aws_instance.api.id
}

# Get the private IP for the HTTP proxy
output "http_proxy_ip" {
  value = aws_instance.http_proxy.private_ip
}

# Role provided to the docbox instance
output "docbox_role" {
  value = aws_iam_role.docbox_role.id
}

# ID for the docbox API security group
output "docbox_api_sg" {
  value = aws_security_group.docbox_api_sg.id
}

# CIDR for the public subnet
output "public_subnet_cidr" {
  value = aws_subnet.public_subnet.cidr_block
}

# CIDR for the first private subnet
output "private_subnet_cidr" {
  value = aws_subnet.private_subnet.cidr_block
}

# ARN for the S3 upload topic
output "sqs_upload_notifications_arn" {
  value = aws_sqs_queue.docbox_queue.arn
}

# URL for the uploads event queue
output "sqs_upload_queue_url" {
  value = aws_sqs_queue.docbox_queue.url
}

# Output the API key (be careful with this in production)
output "typesense_api_key" {
  value     = random_password.typesense_api_key.result
  sensitive = true
}


# Get private IP of API EC2 instance for SSH
output "typesense_private_ip" {
  value = aws_instance.docbox_typesense.private_ip
}

# Generated instance ID for the API EC2 instance 
output "typesense_instance_id" {
  value = aws_instance.docbox_typesense.id
}
