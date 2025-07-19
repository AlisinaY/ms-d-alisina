resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
  })
}
