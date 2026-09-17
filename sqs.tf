# Queue for file upload messages
resource "aws_sqs_queue" "docbox_queue" {
  name = "docbox-s3-upload-queue"

  tags = {
    Name = "docbox-sqs-queue"
  }
}

# Policy on the docbox S3 notification SQS queue that permits AWS S3
# to push new messages onto the queue
resource "aws_sqs_queue_policy" "docbox_s3_sqs_policy" {
  queue_url = aws_sqs_queue.docbox_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "docbox-queue-events"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.docbox_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::docbox-*"
          }
        }
      }
    ]
  })
}
