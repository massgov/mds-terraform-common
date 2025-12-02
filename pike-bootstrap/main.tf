data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  region = data.aws_region.current.region

  policy_files = fileset(path.module, "${var.policy_file_prefix}*.json")

  project_key = substr(md5(var.current_apply_role_name), 0, 6)

  current_role_name = element(split("/", data.aws_caller_identity.current.arn), length(split("/", data.aws_caller_identity.current.arn)) - 2)
}

data "aws_iam_policy_document" "self_manage" {
  statement {
    sid    = "AllowManagingOwnInlinePolicies"
    effect = "Allow"

    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.current_apply_role_name}",
    ]
  }

  statement {
    sid    = "AllowManagingOwnAttachedManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:GetRole",
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.current_apply_role_name}",
    ]
  }

  statement {
    sid    = "DenyUpdatingOwnTrustPolicy"
    effect = "Deny"

    actions = [
      "iam:UpdateAssumeRolePolicy"
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.current_apply_role_name}",
    ]
  }

  # S3 permissions for Terraform state buckets
  statement {
    sid    = "AllowS3TerraformStateAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:ListBucketVersions"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/*"
    ]
  }
  statement {
    sid    = "AllowDynamoDBTerraformStateAccess"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/terraform",
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/terraform/*",
    ]
  }
  statement {
    sid    = "AllowRoleTagging"
    effect = "Allow"
    actions = [
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.current_apply_role_name}"
    ]
  }

  statement {
    sid    = "AllowRoleUpdate"
    effect = "Allow"
    actions = [
      "iam:UpdateRole"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.current_apply_role_name}"
    ]
  }

  statement {
    sid    = "AllowListingPolicies"
    effect = "Allow"
    actions = [
      "iam:ListPolicies",
      "iam:GetPolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManagedPolicyCrud"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:GetPolicyVersion"
    ]
    resources = ["arn:aws:iam::${local.account_id}:policy/${var.current_apply_role_name}*"]
  }
}

resource "aws_iam_policy" "pike_self_manage" {
  name        = "Pike_self_manage_${local.project_key}"
  description = "Policy to allow Pike to manage its own inline policies"
  policy      = data.aws_iam_policy_document.self_manage.json

  lifecycle {
    create_before_destroy = true
  }
}

/* Pike least Privilege Policy for deployment role
   This policy (or policies) are dynamically generated in the GHA runner */
resource "aws_iam_policy" "deploy_least_privilege" {
  for_each    = toset(local.policy_files)
  name        = "deploy_least_privilege_${local.project_key}_${trimsuffix(each.key, ".json")}"
  path        = "/"
  description = "Least-privilege chunk from Pike (split #${replace(each.key, "${var.policy_file_prefix}", "")})"
  policy      = file("${path.module}/${each.value}")
}

resource "aws_iam_role_policy_attachment" "deploy_least_privilege_attach" {
  for_each   = toset(keys(aws_iam_policy.deploy_least_privilege))
  role       = var.current_apply_role_name
  policy_arn = aws_iam_policy.deploy_least_privilege[each.value].arn
}

resource "aws_iam_role_policy_attachment" "pike_gha_attach" {
  role       = var.current_apply_role_name
  policy_arn = aws_iam_policy.pike_self_manage.arn
}
