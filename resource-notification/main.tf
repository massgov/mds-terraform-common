# Data source to get the current AWS region
data "aws_region" "current" {}

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Install dependencies locally
resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = <<EOT
      cd "${path.module}/lambda"
      pip install -r requirements.txt --target ./package
      cp lambda.py ./package/
    EOT
  }
}

# Zip lambda for deployment
data "archive_file" "lambda_package" {
  depends_on = [null_resource.install_dependencies]

  type        = "zip"
  source_file = "${path.module}/lambda/package"
  output_path = "${path.module}/lambda/lambda.zip"
}

# Create SES Email ID, would need to confirm that email used has been approved.
resource "aws_sesv2_email_identity" "ses_sender_email" {
  count          = var.create_ses_email ? 1 : 0
  email_identity = var.sender_email
}

# Inline policy to have access needed for lambda
data "aws_iam_policy_document" "lambda_inline_policy" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.sender_email}"
    ]
  }
  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "ecs:ListClusters",
      "ecs:DescribeServices",
      "ecs:ListServices",
      "rds:DescribeDBInstances",
      "ec2:DescribeInstances"
    ]
    resources = "*"
  }
}

# Create lambda function
module "lambda" {
  source  = "../lambda"
  name    = "resource-ownership-scanner"
  package = data.archive_file.lambda_package.output_path
  runtime = "python3.12"
  environment = {
    SENDER_EMAIL      = var.sender_email
    DEFAULT_RECIPIENT = var.default_recipient
    TESTING           = var.function_testing ? "1" : null
  }
  iam_policies = [data.aws_iam_policy_document.lambda_inline_policy.json]
  schedule     = var.schedule
}