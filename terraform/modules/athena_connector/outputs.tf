output "lambda_arn" {
  description = "ARN of the connector Lambda function"
  value       = aws_lambda_function.connector.arn
}

output "lambda_function_name" {
  description = "Name of the connector Lambda function"
  value       = aws_lambda_function.connector.function_name
}

output "role_arn" {
  description = "ARN of the connector IAM execution role"
  value       = aws_iam_role.connector.arn
}

output "role_name" {
  description = "Name of the connector IAM execution role"
  value       = aws_iam_role.connector.name
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group for the connector"
  value       = aws_cloudwatch_log_group.connector.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group for the connector"
  value       = aws_cloudwatch_log_group.connector.arn
}
