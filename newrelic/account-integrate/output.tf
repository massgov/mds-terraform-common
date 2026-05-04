output "integration_role_arn" {
  description = <<EOF
    The ARN of the IAM role created used by New Relic to access metric stream data. Reference
    this when creating a newrelic_cloud_aws_link_account resource:
    https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/cloud_aws_link_account
  EOF
  value       = try(aws_iam_role.newrelic_integration_role[0].arn, null)
}
