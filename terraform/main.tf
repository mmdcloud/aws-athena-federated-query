# ==============================================================================
# Production-Grade Athena Federated Query Infrastructure
# Data Sources: S3 Data Lake, DynamoDB NoSQL, Amazon RDS (PostgreSQL/MySQL)
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
    }
  )
}

# ------------------------------------------------------------------------------
# 1. Encryption: AWS KMS Customer Managed Key (CMK)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "athena" {
  description             = "KMS Key for Athena Federated Query results, S3 spill, RDS, and Secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowAthenaAndLambdaAccess"
        Effect = "Allow"
        Principal = {
          Service = [
            "athena.amazonaws.com",
            "lambda.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "rds.amazonaws.com",
            "logs.${local.region}.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name = "${local.name_prefix}-kms-key"
    },
    local.common_tags
  )
}

resource "aws_kms_alias" "athena" {
  name          = "alias/${local.name_prefix}-athena-key"
  target_key_id = aws_kms_key.athena.key_id
}

# ------------------------------------------------------------------------------
# 2. Networking: Reusable VPC Module
# ------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  vpc_name                   = "${local.name_prefix}-vpc"
  vpc_cidr                   = var.vpc_cidr
  azs                        = var.azs
  public_subnets             = var.public_subnets
  private_subnets            = var.private_subnets
  enable_dns_hostnames       = true
  enable_dns_support         = true
  create_igw                 = true
  enable_nat_gateway         = false # Cost-optimized: Gateway endpoints route S3 and DynamoDB at $0
  enable_s3_endpoint         = true  # S3 Gateway Endpoint
  enable_dynamodb_endpoint   = true  # DynamoDB Gateway Endpoint
  enable_interface_endpoints = false

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# 3. Storage: S3 Buckets via Reusable S3 Module
# ------------------------------------------------------------------------------

# 3a. Athena Query Results Bucket
module "s3_query_results" {
  source = "./modules/s3"

  bucket_name                            = "${local.name_prefix}-query-results-${local.account_id}"
  force_destroy                          = true
  versioning_enabled                     = "Enabled"
  kms_key_arn                            = aws_kms_key.athena.arn
  expiration_days                        = var.query_results_retention_days
  abort_incomplete_multipart_upload_days = 7

  tags = merge(
    {
      Purpose = "AthenaQueryResults"
    },
    local.common_tags
  )
}

# 3b. Athena Spill Bucket (Mandatory for Athena Federated Connectors)
module "s3_spill" {
  source = "./modules/s3"

  bucket_name                            = "${local.name_prefix}-spill-${local.account_id}"
  force_destroy                          = true
  versioning_enabled                     = "Enabled"
  kms_key_arn                            = aws_kms_key.athena.arn
  expiration_days                        = var.spill_bucket_retention_days
  abort_incomplete_multipart_upload_days = 1

  tags = merge(
    {
      Purpose = "AthenaFederatedQuerySpill"
    },
    local.common_tags
  )
}

# 3c. S3 Data Lake Source Bucket (Stores raw/curated data lake files)
module "s3_data_lake" {
  source = "./modules/s3"

  bucket_name                            = "${local.name_prefix}-data-lake-${local.account_id}"
  force_destroy                          = true
  versioning_enabled                     = "Enabled"
  kms_key_arn                            = aws_kms_key.athena.arn
  expiration_days                        = 0
  abort_incomplete_multipart_upload_days = 7

  # Seed sample ecommerce orders dataset into S3 data lake
  objects = [
    {
      source = "${path.module}/../src/sample_data/orders.csv"
      key    = "orders/orders.csv"
    }
  ]

  tags = merge(
    {
      Purpose = "S3DataLakeSource"
    },
    local.common_tags
  )
}

# ------------------------------------------------------------------------------
# 4. Data Source 1: DynamoDB Table via Reusable DynamoDB Module
# ------------------------------------------------------------------------------
module "dynamodb" {
  source = "./modules/dynamodb"

  name         = "${local.name_prefix}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customer_id"
  attributes = [
    {
      name = "customer_id"
      type = "S"
    }
  ]
  pitr_enabled                   = true
  server_side_encryption_enabled = true
  kms_key_arn                    = aws_kms_key.athena.arn

  tags = merge(
    {
      DataSource = "DynamoDB"
    },
    local.common_tags
  )
}

# Populate initial sample customers data into DynamoDB for query federation
resource "aws_dynamodb_table_item" "sample_customer_1" {
  table_name = module.dynamodb.name
  hash_key   = "customer_id"

  item = jsonencode({
    customer_id = { S = "CUST-001" }
    name        = { S = "Alice Johnson" }
    email       = { S = "alice.johnson@example.com" }
    tier        = { S = "PLATINUM" }
    created_at  = { S = "2025-01-10T08:30:00Z" }
  })
}

resource "aws_dynamodb_table_item" "sample_customer_2" {
  table_name = module.dynamodb.name
  hash_key   = "customer_id"

  item = jsonencode({
    customer_id = { S = "CUST-002" }
    name        = { S = "Bob Smith" }
    email       = { S = "bob.smith@example.com" }
    tier        = { S = "GOLD" }
    created_at  = { S = "2025-02-14T11:15:00Z" }
  })
}

resource "aws_dynamodb_table_item" "sample_customer_3" {
  table_name = module.dynamodb.name
  hash_key   = "customer_id"

  item = jsonencode({
    customer_id = { S = "CUST-003" }
    name        = { S = "Charlie Davis" }
    email       = { S = "charlie.davis@example.com" }
    tier        = { S = "PLATINUM" }
    created_at  = { S = "2025-03-01T14:45:00Z" }
  })
}

# ------------------------------------------------------------------------------
# 5. Data Source 2: Amazon RDS Instance via Reusable RDS Module
# ------------------------------------------------------------------------------

# Random master password for RDS
resource "random_password" "rds_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store database credentials in AWS Secrets Manager (Used by Athena RDS connector)
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${local.name_prefix}-rds-credentials"
  description             = "Database connection credentials for Athena RDS Federated Connector"
  kms_key_id              = aws_kms_key.athena.arn
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    engine              = var.rds_engine
    host                = module.rds.address
    port                = module.rds.port
    username            = var.rds_master_username
    password            = random_password.rds_password.result
    database            = var.rds_db_name
    dbClusterIdentifier = module.rds.id
  })
}

# Security Group for Athena RDS Lambda Connector
resource "aws_security_group" "rds_connector" {
  name        = "${local.name_prefix}-rds-connector-sg"
  description = "Security group for Athena RDS Federated Query Lambda connector"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow outbound to RDS PostgreSQL port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow HTTPS outbound for AWS APIs via Gateway/Interface Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-rds-connector-sg"
    },
    local.common_tags
  )
}

# Security Group for RDS Instance
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-db-sg"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow database connections from Athena RDS Connector Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_connector.id]
  }

  egress {
    description = "Allow outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-rds-db-sg"
    },
    local.common_tags
  )
}

module "rds" {
  source = "./modules/rds"

  identifier              = "${local.name_prefix}-db"
  db_name                 = var.rds_db_name
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.athena.arn
  username                = var.rds_master_username
  password                = random_password.rds_password.result
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 7

  subnet_group_name      = "${local.name_prefix}-rds-subnet-group"
  subnet_group_ids       = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  parameter_group_name   = "${local.name_prefix}-pg"
  parameter_group_family = "postgres16"
  parameters             = []

  tags = merge(
    {
      DataSource = "AmazonRDS"
    },
    local.common_tags
  )
}

# ------------------------------------------------------------------------------
# 6. Athena Federated Connectors via Reusable athena_connector Module
# ------------------------------------------------------------------------------

# Package connector scripts from src/
data "archive_file" "dynamodb_connector_pkg" {
  type        = "zip"
  source_file = "${path.module}/../src/connectors/dynamodb/lambda_function.py"
  output_path = "${path.module}/dynamodb_connector_payload.zip"
}

data "archive_file" "rds_connector_pkg" {
  type        = "zip"
  source_file = "${path.module}/../src/connectors/rds/lambda_function.py"
  output_path = "${path.module}/rds_connector_payload.zip"
}

# 6a. DynamoDB Federated Connector
module "dynamodb_connector" {
  source = "./modules/athena_connector"

  connector_name           = "${local.name_prefix}-dynamodb-connector"
  description              = "Athena Federated Query connector for Amazon DynamoDB"
  spill_bucket_name        = module.s3_spill.bucket
  spill_prefix             = "athena-spill/dynamodb/"
  disable_spill_encryption = false
  kms_key_arn              = aws_kms_key.athena.arn
  lambda_memory_size       = 3008
  lambda_timeout           = 900
  lambda_handler           = "lambda_function.lambda_handler"
  lambda_runtime           = "python3.12"
  lambda_package_path      = data.archive_file.dynamodb_connector_pkg.output_path
  dynamodb_table_arns      = [module.dynamodb.arn]
  log_retention_days       = 30

  tags = merge(
    {
      ConnectorType = "DynamoDB"
    },
    local.common_tags
  )
}

# 6b. RDS PostgreSQL Federated Connector (Runs inside VPC Private Subnets)
module "rds_connector" {
  source = "./modules/athena_connector"

  connector_name              = "${local.name_prefix}-rds-connector"
  description                 = "Athena Federated Query connector for Amazon RDS PostgreSQL"
  spill_bucket_name           = module.s3_spill.bucket
  spill_prefix                = "athena-spill/rds/"
  disable_spill_encryption    = false
  kms_key_arn                 = aws_kms_key.athena.arn
  lambda_memory_size          = 3008
  lambda_timeout              = 900
  lambda_handler              = "lambda_function.lambda_handler"
  lambda_runtime              = "python3.12"
  lambda_package_path         = data.archive_file.rds_connector_pkg.output_path
  secrets_manager_secret_arns = [aws_secretsmanager_secret.rds_credentials.arn]
  log_retention_days          = 30

  # VPC Configuration for RDS private access
  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.rds_connector.id]
  }

  environment_variables = {
    default = "postgres://jdbc:postgresql://${module.rds.endpoint}/${var.rds_db_name}?${aws_secretsmanager_secret.rds_credentials.name}"
  }

  tags = merge(
    {
      ConnectorType = "RDS-PostgreSQL"
    },
    local.common_tags
  )
}

# ------------------------------------------------------------------------------
# 7. Athena Engine, Data Catalogs & Federated Queries via Reusable athena Module
# ------------------------------------------------------------------------------
module "athena" {
  source = "./modules/athena"

  workgroup_name                     = "${local.name_prefix}-${var.athena_workgroup_name}"
  workgroup_description              = "Production Athena Workgroup for cross-source federated queries"
  query_results_bucket_name          = module.s3_query_results.bucket
  kms_key_arn                        = aws_kms_key.athena.arn
  enforce_workgroup_configuration    = true
  publish_cloudwatch_metrics_enabled = true
  force_destroy                      = true

  # Register DynamoDB Data Catalog
  dynamodb_connector_lambda_arn = module.dynamodb_connector.lambda_arn
  dynamodb_catalog_name         = var.dynamodb_catalog_name
  dynamodb_table_name           = module.dynamodb.name

  # Register RDS Data Catalog
  rds_connector_lambda_arn = module.rds_connector.lambda_arn
  rds_catalog_name         = var.rds_catalog_name
  rds_db_name              = "public"
  rds_table_name           = "payment_transactions"

  # Register S3 Data Source via AWS Glue Data Catalog
  enable_s3_glue_catalog = true
  s3_glue_database_name  = "${replace(local.name_prefix, "-", "_")}_lakehouse_db"
  s3_data_bucket_name    = module.s3_data_lake.bucket
  s3_data_prefix         = "orders/"
  s3_table_name          = "orders"

  create_sample_queries = true

  tags = local.common_tags
}
