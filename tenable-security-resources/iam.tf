# policy document for instances to read the scanner secret from param store
data "aws_iam_policy_document" "ec2_scanner_access" {
  statement {
    sid    = "ReadScannerSecret"
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.scanner_secret_parameter_name}"
    ]
  }

  statement {
    sid    = "DecryptScannerSecret"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [var.kms_key_arn]
  }
}

# get all running instances in region tf is running in
data "aws_instances" "running" {
  instance_state_names = ["running"]
}

# get deets of each running instance
data "aws_instance" "running" {
  for_each    = toset(data.aws_instances.running.ids)
  instance_id = each.value
}

# look up each instance profile to get the role name
data "aws_iam_instance_profile" "by_name" {
  for_each = local.unique_instance_profile_names
  name     = each.value
}

resource "aws_iam_role" "lambda" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.lambda_function_name}-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadAndRemediate"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeSecurityGroups",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunSSMCommands"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageIAMPolicies"
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
# auto attach the scanner policy to get all instance roles
resource "aws_iam_role_policy_attachment" "attach_scanner_policy" {
  for_each   = local.unique_role_names
  role       = each.value
  policy_arn = aws_iam_policy.ec2_scanner_access.arn
}

resource "aws_iam_policy" "ec2_scanner_access" {
  name        = "ec2-scanner-secret-access"
  description = "Allows EC2 instances to read the scanner SSH public key from Parameter Store"
  policy      = data.aws_iam_policy_document.ec2_scanner_access.json

  tags = {
    Name      = "EC2 Scanner Secret Access"
    ManagedBy = "terraform"
    Purpose   = "Scanner Bootstrap"
  }
}
