data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/remediate.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 30
}

resource "aws_lambda_function" "remediator" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "remediate.handler"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 420
  memory_size      = 256

  environment {
    variables = {
      VPC_SG_MAPPINGS               = jsonencode(var.vpc_sg_mappings)
      SCANNER_SECRET_PARAMETER_NAME = var.scanner_secret_parameter_name
      SCANNER_USERNAME              = var.scanner_username
      SSM_DOCUMENT_NAME             = aws_ssm_document.scanner_bootstrap.name
      SCANNER_POLICY_ARN            = aws_iam_policy.ec2_scanner_access.arn
      LOG_LEVEL                     = "INFO"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_custom,
    aws_cloudwatch_log_group.lambda,
    aws_ssm_document.scanner_bootstrap,
    aws_iam_policy.ec2_scanner_access
  ]
}
