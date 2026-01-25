# Variables injected into the template
SECRET_NAME="${secret_name}"

# Set the env file contents from the secret value
aws secretsmanager get-secret-value \
    --secret-id $SECRET_NAME \
    --query SecretString \
    --output text | sudo tee /docbox/.env
