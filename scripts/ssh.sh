EC2_HOST=ec2-user@$(terraform output -raw api_private_ip)

ssh -A $EC2_HOST
