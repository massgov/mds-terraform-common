locals {
  aws_accounts_quoted   = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  distribution_names_quoted   = join(", ", formatlist("'%s'", var.filter_distribution_names))
  distribution_names_subquery = length(var.filter_distribution_names) == 0 ? "" : "entity.name IN (${local.distribution_names_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.distribution_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

  error_rate_nql_query = var.custom_error_rate_nql_query != "" ? var.custom_error_rate_nql_query : <<-NRQL
    SELECT average(`aws.cloudfront.TotalErrorRate`) FROM Metric ${local.filter_subquery} FACET entity.name
  NRQL

  important_error_rate_nql_query = <<-NRQL
    SELECT average(`aws.cloudfront.TotalErrorRate`) - average(`aws.cloudfront.4xxErrorRate`) FROM Metric ${local.filter_subquery} FACET entity.name
  NRQL

  throughput_nql_query = var.custom_throughput_nql_query != "" ? var.custom_throughput_nql_query : <<-NRQL
   SELECT average(`aws.cloudfront.Requests`) FROM Metric ${local.filter_subquery} FACET entity.name
  NRQL
}

module "error_rate" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Error rate over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.error_rate_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )
  # if var.include_4xx_errors is false (default is true), we exclude 4xx errors in the error rate calculation
  nrql_query                  = var.include_4xx_errors ? local.error_rate_nql_query : local.important_error_rate_nql_query
  critical_threshold          = var.error_rate_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}

module "throughput" {
  source = "../nrql-alert"
  count  = (var.throughput_enabled ? 1 : 0)

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format("%s - Less than %d requests per %d seconds for over %d seconds",
    var.name_prefix,
    var.throughput_threshold,
    var.aggregation_window,
    var.critical_threshold_duration
  )

  nrql_query = local.throughput_nql_query

  critical_operator           = "below"
  critical_threshold          = var.throughput_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}
