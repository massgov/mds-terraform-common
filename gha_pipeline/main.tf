
data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
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
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}
resource "aws_iam_role_policy_attachment" "policy_attachments" {
  count      = length(var.policy_arns)
  policy_arn = var.policy_arns[count.index]
  role       = aws_iam_role.role.id
}
