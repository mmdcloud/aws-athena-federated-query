output "arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.arn
}

output "name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "id" {
  description = "The ID of the DynamoDB table"
  value       = aws_dynamodb_table.this.id
}
