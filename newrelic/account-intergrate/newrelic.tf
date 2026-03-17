data aws_caller_identity current {}


resource "newrelic_cloud_aws_link_account" "main" {
  depends_on = [aws_iam_role.newrelic_integration_role]
  arn                    = var.newrelic_iam_role_arn != null ? var.newrelic_iam_role_arn : aws_iam_role.newrelic_integration_role[0].arn
  metric_collection_mode = "PULL"
  name                   = var.aws_account_name
}

resource "newrelic_cloud_aws_integrations" "integration" {
  linked_account_id = newrelic_cloud_aws_link_account.main.id


}

