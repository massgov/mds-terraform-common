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
        for oidc_subject_claim in var.oidc_subject_claims : "repo:${var.gh_org}/${var.gh_repo}:${oidc_subject_claim}"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role" "role" {
  name                = var.role_name
  path                = var.role_path
  assume_role_policy  = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = var.policy_arns
  tags = {
    "Name" = var.role_name
  }
}
