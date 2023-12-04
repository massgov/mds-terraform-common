locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  function_names_quoted = join(", ", formatlist("'%s'", var.filter_function_names))
  function_names_subquery = length(var.filter_function_names) == 0 ? "" : "`aws.lambda.FunctionName` IN (${local.function_names_quoted})"

  function_names_exclude_quoted = join(", ", formatlist("'%s'", var.exclude_function_names))
  function_names_exclude_subquery = length(var.exclude_function_names) == 0 ? "" : "`aws.lambda.FunctionName` NOT IN (${local.function_names_exclude_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.function_names_subquery, local.function_names_exclude_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"
}

module "error_percent" {
  source = "../nrql-alert"
  count = (var.error_percent_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  name = format(
    "%s - Error percent over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.error_percent_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = "SELECT average(`aws.lambda.Errors.byFunction`) * 100 FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  critical_threshold = var.error_percent_threshold
  critical_threshold_duration = var.critical_threshold_duration
  fill_option = "last_value"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60
  tags = var.tags
}

module "events_dropped" {
  source = "../nrql-alert"
  count = (var.events_dropped_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  name = format(
    "%s - More than %d events dropped in %d seconds",
    var.name_prefix,
    var.events_dropped_threshold,
    var.critical_threshold_duration
  )

  nrql_query = "SELECT sum(`aws.lambda.AsyncEventsDropped`) FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  critical_threshold = var.events_dropped_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60
  tags = var.tags
}

module "duration" {
  source = "../nrql-alert"
  count = (var.duration_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  name = format(
    "%s - Average function duration greater than %s seconds for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.duration_threshold / 1000), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = "SELECT average(`aws.lambda.Duration.byFunction`) FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  critical_threshold = var.duration_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60
  tags = var.tags
}
