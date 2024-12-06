resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.prefix}-IdentityPoolForLex"
  allow_unauthenticated_identities = true
  allow_classic_flow               = false
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id
  roles = {
    "unauthenticated" = aws_iam_role.unauthenticated.arn
  }
}