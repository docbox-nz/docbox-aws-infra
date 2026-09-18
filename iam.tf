locals {
  rds_db_user_prefix = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_resource_id}"
}

# IAM Policy that allows the docbox role to connect to the docbox databases
resource "aws_iam_policy" "docbox_iam_rds_policy" {
  name        = "docbox_iam_rds_policy"
  description = "Allow access to per tenant database and docbox database credentials"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "rds-db:connect"
      Resource = [
        # Root database role access
        "${local.rds_db_user_prefix}/docbox_config_api",
        # Tenant wildcard database roles access
        "${local.rds_db_user_prefix}/docbox_*_dev_api",
        "${local.rds_db_user_prefix}/docbox_*_prod_api",
      ]
    }]
  })
}

# Policy that allows subscribing to S3 notifications from the SQS queue
resource "aws_iam_policy" "docbox_sqs_read" {
  name        = "sqs_s3_notification_policy"
  description = "Allow docbox EC2 to receive S3 notifications from SQS"

  # The policy document allowing EC2 to read messages from the SQS queue
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "SQS:ReceiveMessage",
          "SQS:DeleteMessage",
          "SQS:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.docbox_queue.arn
      }
    ]
  })
}
