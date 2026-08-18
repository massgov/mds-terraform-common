locals {
  trust_policy   = var.custom_policy_json != "" ? var.custom_policy_json : data.aws_iam_policy_document.assume_policy.json
  subject_prefix = var.allow_legacy_subject ? "repo:${var.gh_org}/${var.gh_repo}" : "repo:${var.gh_org}@${var.org_id}/${var.gh_repo}@${var.repo_id}"

}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test = "StringLike"
      values = [
        for oidc_subject_claim in var.oidc_subject_claims : "${local.subject_prefix}:${oidc_subject_claim}"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.role_name
  path               = var.role_path
  assume_role_policy = local.trust_policy
  tags = {
    "Name" = var.role_name
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.role.name
  policy_arn = each.value
}
