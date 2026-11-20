# ==============================================================================
# Athena Federated Query Terraform Variables
# ==============================================================================

region       = "us-east-1"
environment  = "prod"
project_name = "athena-federation"

# Networking
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

# RDS PostgreSQL Data Source
rds_engine                = "postgres"
rds_engine_version        = "16.3"
rds_instance_class        = "db.t4g.micro"
rds_db_name               = "payments"
rds_master_username       = "dbadmin"
rds_allocated_storage     = 20
rds_max_allocated_storage = 100

# DynamoDB Data Source
dynamodb_table_name = "customers"

# Athena Engine & Connectors
athena_workgroup_name        = "analytics-federation-workgroup"
dynamodb_catalog_name        = "dynamodb_catalog"
rds_catalog_name             = "rds_catalog"
query_results_retention_days = 60
spill_bucket_retention_days  = 7

# Resource Tags
tags = {
  Project     = "AthenaFederatedQuery"
  ManagedBy   = "Terraform"
  Environment = "Production"
  CostCenter  = "DataAnalytics-101"
}
