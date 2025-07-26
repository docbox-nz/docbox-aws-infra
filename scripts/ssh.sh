EC2_HOST=admin@$(terraform output -raw api_private_ip)

ssh -A $EC2_HOST
