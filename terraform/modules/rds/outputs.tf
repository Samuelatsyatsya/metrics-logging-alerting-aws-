output "endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS endpoint port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "security_group_id" {
  description = "Security group ID attached to RDS"
  value       = aws_security_group.rds.id
}

output "credentials_secret_arn" {
  description = "Secrets Manager secret ARN containing DB connection values"
  value       = aws_secretsmanager_secret.credentials.arn
}
