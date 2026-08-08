# Lambda for performing office file conversion
module "office_converter_lambda" {
  source  = "jacobtread/office-convert-lambda/aws"
  version = "0.1.1"

  lambda_function_name      = "docbox-office-convert-lambda"
  lambda_role_name          = "docbox_office_converter_role"
  bucket_access_policy_name = "docbox_office_converter_s3_access_policy"
  temporary_bucket_name     = "docbox-office-converter-tmp"
  invoke_iam_policy_name    = "docbox_office_converter_invoke_policy"
  ecr_repository_name       = "docbox-office-convert-lambda"

  aws_profile  = var.aws_profile
  aws_region   = var.aws_region
  architecture = "arm64"

  lambda_timeout_seconds = 60
  lambda_memory_size     = 2048

  convert_timeout_seconds = 55
}

moved {
  from = aws_lambda_function.office_converter
  to   = module.office_converter_lambda.aws_lambda_function.lambda
}

moved {
  from = aws_ecr_repository.docbox_ecr_private
  to   = module.office_converter_lambda.aws_ecr_repository.ecr
}

moved {
  from = null_resource.trigger_cache_pull
  to   = module.office_converter_lambda.null_resource.trigger_cache_pull
}

moved {
  from = aws_iam_role.docbox_office_converter_role
  to   = module.office_converter_lambda.aws_iam_role.lambda
}

moved {
  from = aws_iam_role_policy_attachment.docbox_office_converter_role_basic_execution
  to   = module.office_converter_lambda.aws_iam_role_policy_attachment.execution
}

moved {
  from = aws_iam_role_policy_attachment.docbox_office_converter_role_converter_s3_access
  to   = module.office_converter_lambda.aws_iam_role_policy_attachment.bucket_access
}

moved {
  from = aws_iam_policy.docbox_office_converter_invoke
  to   = module.office_converter_lambda.aws_iam_policy.invoke
}

moved {
  from = aws_s3_bucket.docbox_office_converter_bucket
  to   = module.office_converter_lambda.aws_s3_bucket.bucket
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.docbox_office_converter_bucket_lifecycle
  to   = module.office_converter_lambda.aws_s3_bucket_lifecycle_configuration.bucket_lifecycle
}
