output "workgroup_id" {
  description = "The ID of the Athena workgroup"
  value       = aws_athena_workgroup.primary.id
}

output "workgroup_arn" {
  description = "The ARN of the Athena workgroup"
  value       = aws_athena_workgroup.primary.arn
}

output "workgroup_name" {
  description = "The name of the Athena workgroup"
  value       = aws_athena_workgroup.primary.name
}

output "dynamodb_catalog_name" {
  description = "Name of the DynamoDB Athena data catalog"
  value       = try(aws_athena_data_catalog.dynamodb[0].name, null)
}

output "rds_catalog_name" {
  description = "Name of the RDS Athena data catalog"
  value       = try(aws_athena_data_catalog.rds[0].name, null)
}

output "glue_database_name" {
  description = "Name of the Glue Catalog database for S3 data lake"
  value       = try(aws_glue_catalog_database.s3_database[0].name, null)
}

output "glue_table_name" {
  description = "Name of the Glue Catalog table for S3 orders"
  value       = try(aws_glue_catalog_table.s3_orders[0].name, null)
}

output "federated_named_query_id" {
  description = "ID of the sample cross-source federated named query"
  value       = try(aws_athena_named_query.federated_cross_source_join[0].id, null)
}
