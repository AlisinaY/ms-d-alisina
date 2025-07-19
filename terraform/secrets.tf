resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "microservices-demo/app-secrets"
  description = "Sensitive credentials for microservices-demo"
}

resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    DB_HOST         = var.db_host
    DB_NAME         = var.db_name
    DB_USER         = var.db_user
    DB_PASSWORD     = var.db_password
    OPENAI_API_KEY  = var.openai_api_key
  })
}
