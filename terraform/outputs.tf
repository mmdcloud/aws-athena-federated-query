# ==============================================================================
# Terraform Outputs: Athena Federated Query Infrastructure
# ==============================================================================

# Athena Workgroup Outputs
output "athena_workgroup_id" {
  description = "The ID of the Athena Workgroup configured for federated query execution"
  value       = module.athena.workgroup_id
}

output "athena_workgroup_arn" {
  description = "The ARN of the Athena Workgroup"
  value       = module.athena.workgroup_arn
}

output "athena_workgroup_name" {
  description = "The name of the Athena Workgroup"
  value       = module.athena.workgroup_name
}

# KMS Outputs
output "kms_key_arn" {
  description = "ARN of the centralized KMS Customer Managed Key (CMK)"
  value       = module.kms.arn
}

output "kms_key_alias" {
  description = "Alias name for the KMS Key"
  value       = module.kms.alias_name
}

# S3 Buckets Outputs
output "s3_query_results_bucket" {
  description = "S3 bucket storing Athena query execution results"
  value       = module.s3_query_results.bucket
}

output "s3_spill_bucket" {
  description = "S3 spill bucket used by Athena Federated Query connectors for overflow partitions"
  value       = module.s3_spill.bucket
}

output "s3_data_lake_bucket" {
  description = "S3 data lake bucket holding raw ecommerce orders data"
  value       = module.s3_data_lake.bucket
}

# Data Source 1: DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table data source"
  value       = module.dynamodb.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table data source"
  value       = module.dynamodb.arn
}

output "dynamodb_connector_lambda_arn" {
  description = "ARN of the Athena DynamoDB connector Lambda function"
  value       = module.dynamodb_connector.lambda_arn
}

output "dynamodb_catalog_name" {
  description = "Athena Federated Data Catalog name registered for DynamoDB"
  value       = module.athena.dynamodb_catalog_name
}

# Data Source 2: RDS Outputs
output "rds_instance_endpoint" {
  description = "Endpoint of the RDS PostgreSQL database"
  value       = module.rds.endpoint
}

output "rds_instance_address" {
  description = "Hostname/Address of the RDS database"
  value       = module.rds.address
}

output "rds_instance_port" {
  description = "Port of the RDS database"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "Database name inside the RDS instance"
  value       = module.rds.name
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret storing RDS connection credentials"
  value       = module.secrets_manager.arn
}

output "rds_connector_lambda_arn" {
  description = "ARN of the Athena RDS connector Lambda function"
  value       = module.rds_connector.lambda_arn
}

output "rds_catalog_name" {
  description = "Athena Federated Data Catalog name registered for RDS"
  value       = module.athena.rds_catalog_name
}

# Data Source 3: S3 / Glue Outputs
output "glue_database_name" {
  description = "Name of the AWS Glue Catalog database for S3 data source"
  value       = module.athena.glue_database_name
}

output "glue_orders_table_name" {
  description = "Name of the AWS Glue Catalog table for S3 orders dataset"
  value       = module.athena.glue_table_name
}

# Federated Query Analytics
output "sample_federated_join_query_id" {
  description = "Athena Named Query ID for 3-way join across S3, DynamoDB, and RDS"
  value       = module.athena.federated_named_query_id
}

output "sample_federated_query_example" {
  description = "SQL snippet demonstrating the cross-source federated join"
  value       = <<-SQL
    SELECT 
      o.order_id,
      o.order_date,
      o.order_amount,
      c.name AS customer_name,
      c.email AS customer_email,
      t.transaction_id,
      t.payment_status
    FROM "AwsDataCatalog"."${module.athena.glue_database_name}"."orders" o
    JOIN "${module.athena.dynamodb_catalog_name}"."default"."${module.dynamodb.name}" c
      ON o.customer_id = c.customer_id
    JOIN "${module.athena.rds_catalog_name}"."public"."payment_transactions" t
      ON o.order_id = t.order_id
    WHERE o.order_status = 'COMPLETED';
  SQL
}
