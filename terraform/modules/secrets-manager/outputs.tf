output "name" {
  description = "The name of the secret"
  value       = aws_secretsmanager_secret.secret.name
}

output "arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.secret.arn
}

output "id" {
  description = "The ID of the secret"
  value       = aws_secretsmanager_secret.secret.id
}

output "version_id" {
  description = "The unique identifier of the version of the secret"
  value       = aws_secretsmanager_secret_version.secret_version.version_id
}
