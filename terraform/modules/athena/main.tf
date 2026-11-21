# ------------------------------------------------------------------------------
# Athena Workgroup
# ------------------------------------------------------------------------------
resource "aws_athena_workgroup" "primary" {
  name          = var.workgroup_name
  description   = var.workgroup_description
  state         = "ENABLED"
  force_destroy = var.force_destroy

  configuration {
    enforce_workgroup_configuration    = var.enforce_workgroup_configuration
    publish_cloudwatch_metrics_enabled = var.publish_cloudwatch_metrics_enabled
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query

    result_configuration {
      output_location = "s3://${var.query_results_bucket_name}/results/"

      encryption_configuration {
        encryption_option = var.kms_key_arn != null ? "SSE_KMS" : "SSE_S3"
        kms_key_arn       = var.kms_key_arn
      }
    }
  }

  tags = merge(
    {
      Name = var.workgroup_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Athena Federated Data Catalog - DynamoDB
# ------------------------------------------------------------------------------
resource "aws_athena_data_catalog" "dynamodb" {
  count       = var.enable_dynamodb_catalog ? 1 : 0
  name        = var.dynamodb_catalog_name
  description = "Athena Federated Query connector for Amazon DynamoDB"
  type        = "LAMBDA"

  parameters = {
    "function" = var.dynamodb_connector_lambda_arn
  }

  tags = merge(
    {
      Name = var.dynamodb_catalog_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Athena Federated Data Catalog - RDS
# ------------------------------------------------------------------------------
resource "aws_athena_data_catalog" "rds" {
  count       = var.enable_rds_catalog ? 1 : 0
  name        = var.rds_catalog_name
  description = "Athena Federated Query connector for Amazon RDS"
  type        = "LAMBDA"

  parameters = {
    "function" = var.rds_connector_lambda_arn
  }

  tags = merge(
    {
      Name = var.rds_catalog_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# S3 Data Source via AWS Glue Data Catalog
# ------------------------------------------------------------------------------
resource "aws_glue_catalog_database" "s3_database" {
  count       = var.enable_s3_glue_catalog ? 1 : 0
  name        = var.s3_glue_database_name
  description = "AWS Glue Catalog Database for S3 Data Lake data source"
}

resource "aws_glue_catalog_table" "s3_orders" {
  count         = var.enable_s3_glue_catalog ? 1 : 0
  database_name = aws_glue_catalog_database.s3_database[0].name
  name          = var.s3_table_name
  description   = "S3 external table for ecommerce orders"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"         = "csv"
    "compressionType"        = "none"
    "typeOfData"             = "file"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${var.s3_data_bucket_name}/${var.s3_data_prefix}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "OpenCSVSerde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
      }
    }

    columns {
      name = "order_id"
      type = "string"
    }
    columns {
      name = "customer_id"
      type = "string"
    }
    columns {
      name = "order_date"
      type = "string"
    }
    columns {
      name = "order_amount"
      type = "double"
    }
    columns {
      name = "order_status"
      type = "string"
    }
  }
}

# ------------------------------------------------------------------------------
# Athena Named Queries (Federated Cross-Source Analytics Queries)
# ------------------------------------------------------------------------------

# 1. 3-Way Federated Join: S3 + DynamoDB + RDS
resource "aws_athena_named_query" "federated_cross_source_join" {
  count       = var.create_sample_queries && var.enable_dynamodb_catalog && var.enable_rds_catalog && var.enable_s3_glue_catalog ? 1 : 0
  name        = "federated_cross_source_join"
  workgroup   = aws_athena_workgroup.primary.id
  database    = var.enable_s3_glue_catalog ? aws_glue_catalog_database.s3_database[0].name : "default"
  description = "3-way federated join across S3 (Orders), DynamoDB (Customers), and RDS (Transactions)"

  query = <<-SQL
    -- Athena Federated Query: 3-Way Join Across S3, DynamoDB, and RDS
    -- 1. S3 Data Lake: Orders data via AWS Glue Catalog
    -- 2. DynamoDB: Customer profile details via DynamoDB connector
    -- 3. RDS: Transaction payment verification via RDS connector
    SELECT 
      o.order_id,
      o.order_date,
      o.order_amount,
      o.order_status,
      c.customer_id,
      c.name AS customer_name,
      c.email AS customer_email,
      c.tier AS customer_tier,
      t.transaction_id,
      t.payment_method,
      t.payment_status
    FROM "AwsDataCatalog"."${var.s3_glue_database_name}"."${var.s3_table_name}" o
    JOIN "${var.dynamodb_catalog_name}"."default"."${var.dynamodb_table_name}" c
      ON o.customer_id = c.customer_id
    JOIN "${var.rds_catalog_name}"."${var.rds_db_name}"."${var.rds_table_name}" t
      ON o.order_id = t.order_id
    WHERE o.order_status = 'COMPLETED'
    ORDER BY o.order_amount DESC
    LIMIT 100;
  SQL
}

# 2. DynamoDB Direct Federated Query
resource "aws_athena_named_query" "dynamodb_direct_query" {
  count       = var.create_sample_queries && var.enable_dynamodb_catalog ? 1 : 0
  name        = "dynamodb_direct_query"
  workgroup   = aws_athena_workgroup.primary.id
  database    = "default"
  description = "Direct federated query against DynamoDB customer profile table"

  query = <<-SQL
    SELECT 
      customer_id,
      name,
      email,
      tier,
      created_at
    FROM "${var.dynamodb_catalog_name}"."default"."${var.dynamodb_table_name}"
    LIMIT 50;
  SQL
}

# 3. RDS Direct Federated Query
resource "aws_athena_named_query" "rds_direct_query" {
  count       = var.create_sample_queries && var.enable_rds_catalog ? 1 : 0
  name        = "rds_direct_query"
  workgroup   = aws_athena_workgroup.primary.id
  database    = "default"
  description = "Direct federated query against RDS payment transaction table"

  query = <<-SQL
    SELECT 
      transaction_id,
      order_id,
      amount,
      payment_method,
      payment_status,
      created_at
    FROM "${var.rds_catalog_name}"."${var.rds_db_name}"."${var.rds_table_name}"
    WHERE payment_status = 'SUCCESS'
    LIMIT 50;
  SQL
}

# 4. S3 Lakehouse Direct Query
resource "aws_athena_named_query" "s3_direct_query" {
  count       = var.create_sample_queries && var.enable_s3_glue_catalog ? 1 : 0
  name        = "s3_direct_query"
  workgroup   = aws_athena_workgroup.primary.id
  database    = aws_glue_catalog_database.s3_database[0].name
  description = "Direct query against S3 lakehouse orders table"

  query = <<-SQL
    SELECT 
      order_id,
      customer_id,
      order_date,
      order_amount,
      order_status
    FROM "AwsDataCatalog"."${var.s3_glue_database_name}"."${var.s3_table_name}"
    LIMIT 50;
  SQL
}
