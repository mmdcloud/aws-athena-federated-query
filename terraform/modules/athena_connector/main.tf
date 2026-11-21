data "archive_file" "default_package" {
  count       = var.lambda_package_path == null ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/default_connector_payload.zip"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "connector" {
  name              = "/aws/lambda/${var.connector_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_arn

  tags = merge(
    {
      Name = "/aws/lambda/${var.connector_name}"
    },
    var.tags
  )
}

# IAM Role for Lambda Connector
resource "aws_iam_role" "connector" {
  name        = "${var.connector_name}-role"
  description = "IAM execution role for Athena Federated Query connector ${var.connector_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.connector_name}-role"
    },
    var.tags
  )
}

# Least-Privilege IAM Policy for Athena Connector
resource "aws_iam_policy" "connector" {
  name        = "${var.connector_name}-policy"
  description = "IAM policy for Athena Federated Query connector ${var.connector_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # CloudWatch Logs permissions
      [
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "${aws_cloudwatch_log_group.connector.arn}:*"
        }
      ],
      # S3 Spill Bucket permissions
      [
        {
          Sid    = "AthenaSpillBucketAccess"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::${var.spill_bucket_name}/${var.spill_prefix}*"
        },
        {
          Sid    = "AthenaSpillBucketList"
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = "arn:aws:s3:::${var.spill_bucket_name}"
        }
      ],
      # Athena Query Execution permissions
      [
        {
          Sid    = "AthenaQueryExecution"
          Effect = "Allow"
          Action = [
            "athena:GetQueryExecution"
          ]
          Resource = "*"
        }
      ],
      # DynamoDB permissions (if table ARNs are supplied)
      length(var.dynamodb_table_arns) > 0 ? [
        {
          Sid    = "DynamoDBReadAccess"
          Effect = "Allow"
          Action = [
            "dynamodb:DescribeTable",
            "dynamodb:GetItem",
            "dynamodb:BatchGetItem",
            "dynamodb:Scan",
            "dynamodb:Query"
          ]
          Resource = concat(
            var.dynamodb_table_arns,
            [for arn in var.dynamodb_table_arns : "${arn}/index/*"]
          )
        }
      ] : [],
      # Secrets Manager permissions (for RDS connection credentials)
      length(var.secrets_manager_secret_arns) > 0 ? [
        {
          Sid    = "SecretsManagerAccess"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          Resource = var.secrets_manager_secret_arns
        }
      ] : [],
      # KMS Decryption permissions (if KMS Key ARN is supplied)
      var.kms_key_arn != null ? [
        {
          Sid    = "KMSDecryptAccess"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:DescribeKey"
          ]
          Resource = [var.kms_key_arn]
        }
      ] : [],
      # VPC ENI permissions (if VPC config is supplied for RDS access)
      var.vpc_config != null ? [
        {
          Sid    = "VPCENIManagement"
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
          ]
          Resource = "*"
        }
      ] : []
    )
  })

  tags = var.tags
}

# Role-Policy Attachment
resource "aws_iam_role_policy_attachment" "connector" {
  role       = aws_iam_role.connector.name
  policy_arn = aws_iam_policy.connector.arn
}

# Lambda Function for Connector
resource "aws_lambda_function" "connector" {
  function_name = var.connector_name
  description   = var.description
  role          = aws_iam_role.connector.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = var.lambda_package_path != null ? var.lambda_package_path : data.archive_file.default_package[0].output_path
  source_code_hash = var.lambda_package_path != null ? filebase64sha256(var.lambda_package_path) : data.archive_file.default_package[0].output_base64sha256

  environment {
    variables = merge(
      {
        spill_bucket             = var.spill_bucket_name
        spill_prefix             = var.spill_prefix
        disable_spill_encryption = var.disable_spill_encryption ? "true" : "false"
      },
      var.environment_variables
    )
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.connector,
    aws_iam_role_policy_attachment.connector
  ]

  tags = merge(
    {
      Name = var.connector_name
    },
    var.tags
  )
}

# Allow Athena to invoke the connector Lambda function
resource "aws_lambda_permission" "allow_athena" {
  statement_id  = "AllowAthenaFederationInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connector.function_name
  principal     = "athena.amazonaws.com"
}
