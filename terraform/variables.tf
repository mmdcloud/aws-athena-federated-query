variable "region" {
  description = "AWS region for all deployed resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project identifier for resource naming and tagging"
  type        = string
  default     = "athena-federation"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for multi-AZ subnet deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks for RDS and Athena VPC connector"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# RDS Data Source Variables
variable "rds_engine" {
  description = "The database engine for RDS data source"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Engine version for the RDS database"
  type        = string
  default     = "16.3"
}

variable "rds_instance_class" {
  description = "Instance type for the RDS instance"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_db_name" {
  description = "The initial database name created inside RDS"
  type        = string
  default     = "payments"
}

variable "rds_master_username" {
  description = "Master username for the RDS database instance"
  type        = string
  default     = "dbadmin"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Autoscaling storage upper limit for RDS in GB"
  type        = number
  default     = 100
}

# DynamoDB Data Source Variables
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table data source"
  type        = string
  default     = "customers"
}

# Athena & Connector Configuration
variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
  default     = "analytics-federation-workgroup"
}

variable "dynamodb_catalog_name" {
  description = "Athena Federated Data Catalog name for DynamoDB"
  type        = string
  default     = "dynamodb_catalog"
}

variable "rds_catalog_name" {
  description = "Athena Federated Data Catalog name for RDS"
  type        = string
  default     = "rds_catalog"
}

variable "query_results_retention_days" {
  description = "Days to retain Athena query output results in S3 before expiration"
  type        = number
  default     = 60
}

variable "spill_bucket_retention_days" {
  description = "Days to retain spilled partition data in S3 before expiration"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AthenaFederatedQuery"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}
