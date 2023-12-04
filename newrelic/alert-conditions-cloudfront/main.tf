locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  distribution_names_quoted = join(", ", formatlist("'%s'", var.filter_distribution_names))
  distribution_names_subquery = length(var.filter_distribution_names) == 0 ? "" : "entity.name IN (${local.distribution_names_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.distribution_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

}

module "error_rate" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id = var.alert_policy_id
  name = format(
    "%s - Error rate over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.error_rate_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = "SELECT average(aws.cloudfront.TotalErrorRate) FROM Metric ${local.filter_subquery} FACET entity.name"
  critical_threshold = var.error_rate_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window = var.aggregation_window
  aggregation_method = "event_flow"
  aggregation_delay = 120
  tags = var.tags
}

module "throughput" {
  source = "../nrql-alert"
  count = (var.throughput_enabled ? 1 : 0)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  name = format("%s - Less than %d requests per %d seconds for over %d seconds",
    var.name_prefix,
    var.throughput_threshold,
    var.aggregation_window,
    var.critical_threshold_duration
  )

  nrql_query = "SELECT average(aws.cloudfront.Requests) FROM Metric ${local.filter_subquery} FACET entity.name"

  critical_operator = "below"
  critical_threshold = var.throughput_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window = var.aggregation_window
  aggregation_method = "event_flow"
  aggregation_delay = 120
  tags = var.tags
}
