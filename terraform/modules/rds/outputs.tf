output "endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.db.endpoint
}

output "arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.db.arn
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.db.address
}

output "port" {
  description = "The database port"
  value       = aws_db_instance.db.port
}

output "name" {
  description = "The database name"
  value       = aws_db_instance.db.db_name
}

output "username" {
  description = "The master username for the database"
  value       = aws_db_instance.db.username
}

output "id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.db.id
}
