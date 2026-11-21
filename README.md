# Production-Grade AWS Athena Federated Query Infrastructure

This repository provides a modular, production-ready **Terraform** configuration for **Amazon Athena Federated Query**, enabling cross-source SQL queries across **Amazon S3**, **Amazon DynamoDB**, and **Amazon RDS (PostgreSQL/MySQL)** without moving or ETL-ing data.

---

## 🏛 Architecture Overview

```
                      ┌───────────────────────────────────────────────┐
                      │              Amazon Athena Engine             │
                      │         (Dedicated Custom Workgroup)          │
                      └───────┬───────────────┬───────────────┬───────┘
                              │               │               │
             Direct SQL       │               │ Invoke        │ Invoke
             via Glue         │               │               │
                              ▼               ▼               ▼
                      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
                      │   AWS Glue   │ │ DynamoDB     │ │ RDS JDBC     │
                      │ Data Catalog │ │ Connector    │ │ Connector    │
                      │              │ │ (Lambda)     │ │ (VPC Lambda) │
                      └───────┬──────┘ └──────┬───────┘ └──────┬───────┘
                              │               │                │
                              ▼               ▼                ▼
                      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
                      │  Amazon S3   │ │Amazon        │ │  Amazon RDS  │
                      │  Data Lake   │ │DynamoDB      │ │ (PostgreSQL) │
                      │ (Orders CSV) │ │(Customers)   │ │(Transactions)│
                      └──────────────┘ └──────────────┘ └──────────────┘
                              ▲               ▲                ▲
                              │               │                │
                      ┌───────┴───────────────┴────────────────┴───────┐
                      │             Amazon S3 Spill Bucket             │
                      │        (Temporary Partition Spillover)         │
                      └────────────────────────────────────────────────┘
```

### Components

1. **Athena Workgroup (`analytics-federation-workgroup`)**:
   - Enforces workgroup configuration, query encryption via KMS CMK, CloudWatch metrics, and dedicated query result storage in S3.
2. **Athena Federated Connectors (AWS Lambda)**:
   - **DynamoDB Connector**: Invoked by Athena to read table metadata and scan/query DynamoDB records.
   - **RDS PostgreSQL Connector**: VPC-enabled Lambda deployed in private subnets with least-privilege egress to the RDS instance and access to AWS Secrets Manager.
3. **Data Sources**:
   - **Amazon S3**: Raw ecommerce orders data cataloged via AWS Glue Data Catalog external table (`s3_lakehouse_db.orders`).
   - **Amazon DynamoDB**: Key-value customer profile store (`customers`) with server-side KMS encryption and PITR.
   - **Amazon RDS (PostgreSQL)**: Relational database in private VPC subnets with KMS encryption and automated backups for payment transactions.
4. **S3 Spill Bucket**:
   - Stores overflow partitions in Apache Arrow / Parquet format whenever query results exceed Lambda memory limits. Configured with a 7-day automatic lifecycle expiration and multipart upload abort.
5. **AWS Secrets Manager & KMS**:
   - Stores database credentials and encrypts S3 buckets, RDS storage, and CloudWatch logs.

---

## 📁 Repository Structure

```
.
├── src/
│   ├── connectors/
│   │   ├── dynamodb/
│   │   │   └── lambda_function.py      # Production DynamoDB Athena connector
│   │   └── rds/
│   │       └── lambda_function.py      # Production RDS PostgreSQL Athena connector
│   └── sample_data/
│       ├── orders.csv                  # Sample data seeded into S3 data lake
│       └── init_rds.sql                # SQL initialization script for RDS database
└── terraform/
    ├── provider.tf                     # Provider definitions (AWS, Random, Archive)
    ├── main.tf                         # Root module orchestrating all infrastructure
    ├── variables.tf                    # Input variable declarations
    ├── outputs.tf                      # Output values (Workgroup, Catalogs, ARNs, Queries)
    ├── terraform.tfvars                # Default configuration values
    ├── terraform.tfvars.example        # Example configuration template
    └── modules/
        ├── athena/                     # Workgroup, Data Catalogs, Glue tables & Named Queries
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── athena_connector/           # Reusable Athena Lambda connector module
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── src/handler.py
        ├── dynamodb/                   # Reusable DynamoDB module
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── rds/                        # Reusable RDS instance module
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── s3/                         # Reusable S3 bucket module (KMS, lifecycle, public block)
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── vpc/                        # Reusable VPC networking with Gateway/Interface Endpoints
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── kms/                        # Reusable KMS key and alias module
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── secrets-manager/            # Reusable Secrets Manager secret and version module
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── security-groups/            # Reusable dynamic security group module
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── iam/                        # Reusable IAM role and policy module
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## 🚀 Deployment Instructions

### Prerequisites
- [Terraform >= 1.5.0](https://www.terraform.io/downloads.html)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate IAM credentials
- PostgreSQL client (`psql`) or database tool (e.g., DBeaver) for initializing RDS data

### 1. Initialize and Validate Terraform
```bash
cd terraform
terraform init
terraform validate
```

### 2. Plan and Review
Review the proposed resources:
```bash
terraform plan -out=tfplan
```

### 3. Deploy Infrastructure
```bash
terraform apply tfplan
```

---

## 🗄 Populating Data Sources

### S3 Data Lake
The Terraform module automatically uploads `src/sample_data/orders.csv` to the S3 data lake bucket (`orders/orders.csv`) and creates the AWS Glue catalog external table.

### DynamoDB Table
The Terraform configuration seeds sample customer records directly into the DynamoDB table during deployment:
- `CUST-001`: Alice Johnson (PLATINUM)
- `CUST-002`: Bob Smith (GOLD)
- `CUST-003`: Charlie Davis (PLATINUM)

### RDS PostgreSQL Instance
Connect to the RDS instance through a bastion host or from inside the VPC and run the initialization script:
```bash
# Retrieve connection parameters from Terraform output
DB_ENDPOINT=$(terraform output -raw rds_instance_address)
DB_SECRET_ARN=$(terraform output -raw rds_credentials_secret_arn)

# Execute initialization SQL
psql -h $DB_ENDPOINT -U dbadmin -d payments -f ../src/sample_data/init_rds.sql
```

---

## 🔍 Running Federated Queries

Open the **Amazon Athena Console**, select the **`athena-federation-prod-analytics-federation-workgroup`** workgroup, and execute the pre-configured Named Query:

### 3-Way Cross-Source Federated Join:
```sql
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
FROM "AwsDataCatalog"."athena_federation_prod_lakehouse_db"."orders" o
JOIN "dynamodb_catalog"."default"."athena-federation-prod-customers" c
  ON o.customer_id = c.customer_id
JOIN "rds_catalog"."public"."payment_transactions" t
  ON o.order_id = t.order_id
WHERE o.order_status = 'COMPLETED'
ORDER BY o.order_amount DESC;
```

---

## 🛡 Production Best Practices Implemented

1. **Least Privilege IAM**:
   - Connector Lambda functions have dedicated IAM roles strictly restricted to their respective data sources, the S3 spill bucket prefix, and CloudWatch logs.
   - Athena invoke permissions are explicitly scoped using `aws_lambda_permission` with principal `athena.amazonaws.com`.
2. **KMS Encryption at Rest**:
   - Customer Managed Key (CMK) with automated 1-year rotation encrypts S3 query results, S3 spill partitions, RDS storage, and CloudWatch logs.
3. **Zero-Cost VPC Gateway Endpoints**:
   - S3 and DynamoDB Gateway VPC Endpoints are provisioned inside the VPC route tables, eliminating NAT gateway bandwidth costs for internal data transfers.
4. **Network Isolation**:
   - RDS is placed in private VPC subnets with no public accessibility.
   - The RDS Athena connector runs within the VPC private subnets, with security groups strictly allowing outbound port 5432 only to the RDS instance.
5. **Spill Storage Lifecycle**:
   - Spill bucket automatically aborts incomplete multipart uploads after 24 hours and expires spilled temporary partitions after 7 days to prevent unnecessary storage costs.
