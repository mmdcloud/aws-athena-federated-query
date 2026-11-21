variable "workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
}

variable "workgroup_description" {
  description = "Description of the Athena workgroup"
  type        = string
  default     = "Athena Workgroup for Federated Queries"
}

variable "query_results_bucket_name" {
  description = "S3 bucket name where Athena stores query results"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN for encrypting Athena query results"
  type        = string
  default     = null
}

variable "enforce_workgroup_configuration" {
  description = "Whether to enforce workgroup configuration on queries run in this workgroup"
  type        = bool
  default     = true
}

variable "publish_cloudwatch_metrics_enabled" {
  description = "Whether to publish query metrics to CloudWatch"
  type        = bool
  default     = true
}

variable "bytes_scanned_cutoff_per_query" {
  description = "The upper data usage limit (in bytes) for queries in this workgroup (null for unlimited)"
  type        = number
  default     = null
}

variable "force_destroy" {
  description = "Option to delete the workgroup and its contents even if it has queries"
  type        = bool
  default     = false
}

# DynamoDB Connector Integration
variable "enable_dynamodb_catalog" {
  description = "Whether to register the DynamoDB data catalog in Athena"
  type        = bool
  default     = true
}

variable "dynamodb_connector_lambda_arn" {
  description = "Lambda ARN for the DynamoDB connector"
  type        = string
  default     = null
}

variable "dynamodb_catalog_name" {
  description = "Athena Catalog name for DynamoDB connector"
  type        = string
  default     = "dynamodb_catalog"
}

variable "dynamodb_table_name" {
  description = "Target DynamoDB table name for sample named queries"
  type        = string
  default     = "customers"
}

# RDS Connector Integration
variable "enable_rds_catalog" {
  description = "Whether to register the RDS data catalog in Athena"
  type        = bool
  default     = true
}

variable "rds_connector_lambda_arn" {
  description = "Lambda ARN for the RDS connector"
  type        = string
  default     = null
}

variable "rds_catalog_name" {
  description = "Athena Catalog name for RDS connector"
  type        = string
  default     = "rds_catalog"
}

variable "rds_db_name" {
  description = "Target database name inside RDS for sample queries"
  type        = string
  default     = "public"
}

variable "rds_table_name" {
  description = "Target table name inside RDS for sample queries"
  type        = string
  default     = "payment_transactions"
}

# S3 Glue Catalog Integration
variable "enable_s3_glue_catalog" {
  description = "Whether to create AWS Glue Catalog database and table for S3 data source"
  type        = bool
  default     = true
}

variable "s3_glue_database_name" {
  description = "AWS Glue Catalog database name for S3 data lake"
  type        = string
  default     = "s3_lakehouse_db"
}

variable "s3_data_bucket_name" {
  description = "Name of the S3 bucket hosting data lake files"
  type        = string
  default     = null
}

variable "s3_data_prefix" {
  description = "S3 prefix/folder path where raw data is stored"
  type        = string
  default     = "orders/"
}

variable "s3_table_name" {
  description = "Name of the Glue table representing S3 data"
  type        = string
  default     = "orders"
}

variable "create_sample_queries" {
  description = "Whether to create sample Athena named queries demonstrating federation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
