# Create the .env file secret
resource "aws_secretsmanager_secret" "docbox_env_secret" {
  name        = "docbox-env-file"
  description = ".env file for the docbox server"
}
