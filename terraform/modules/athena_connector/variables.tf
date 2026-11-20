variable "connector_name" {
  description = "Unique name for the Athena Federated Query connector Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the connector Lambda function"
  type        = string
  default     = "Athena Federated Query Connector"
}

variable "spill_bucket_name" {
  description = "Name of the S3 spill bucket used by Athena connectors for large query spillover"
  type        = string
}

variable "spill_prefix" {
  description = "Prefix inside the S3 spill bucket for this connector"
  type        = string
  default     = "athena-spill/"
}

variable "disable_spill_encryption" {
  description = "Whether to disable encryption on spilled data in S3 (should be false in production)"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS Key ARN for encrypting CloudWatch logs, spill data, and Secrets"
  type        = string
  default     = null
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda connector in MB (Athena connectors recommend 3008 MB)"
  type        = number
  default     = 3008
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda connector in seconds (Athena max timeout 900s)"
  type        = number
  default     = 900
}

variable "lambda_package_path" {
  description = "Custom path to a zip file containing the connector package. If null, default package is used."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Custom environment variables to pass to the connector Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for relational connectors (RDS, Aurora, etc.) requiring private subnet access"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs that the connector needs read access to"
  type        = list(string)
  default     = []
}

variable "secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs that the connector needs read access to (e.g. for DB credentials)"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
