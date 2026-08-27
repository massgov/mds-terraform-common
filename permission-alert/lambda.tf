# Build the TypeScript Lambda locally using esbuild
resource "null_resource" "build_lambda" {
  triggers = {
    src_hash      = filesha256("${path.module}/lambda/src/index.ts")
    pkg_hash      = filesha256("${path.module}/lambda/package.json")
    lock_hash     = fileexists("${path.module}/lambda/package-lock.json") ? filesha256("${path.module}/lambda/package-lock.json") : ""
    tsconfig_hash = filesha256("${path.module}/lambda/tsconfig.json")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/lambda && npm ci && npm run build"
  }
}

data "archive_file" "detector_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/dist/index.js"
  output_path = "${path.module}/lambda/detector.zip"

  depends_on = [null_resource.build_lambda]
}

resource "aws_lambda_function" "detector" {
  function_name = "role-admin-detector"
  role          = aws_iam_role.detector_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.detector_zip.output_path
  source_code_hash = data.archive_file.detector_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      TARGET_ROLES  = join(",", var.role_names)
    }
  }

  timeout = 30
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_changes.arn
}
