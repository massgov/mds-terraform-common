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

resource "newrelic_nrql_alert_condition" "error_percent" {
  count = (var.error_percent_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Error Percent"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(`aws.lambda.Errors.byFunction`) * 100 FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  }

  critical {
    operator = "above"
    threshold = var.error_percent_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }

  fill_option = "last_value"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60

  open_violation_on_expiration = false
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "events_dropped" {
  count = (var.events_dropped_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Events Dropped"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT sum(`aws.lambda.AsyncEventsDropped`) FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  }

  critical {
    operator = "above"
    threshold = var.events_dropped_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }

  fill_option = "none"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60

  open_violation_on_expiration = false
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "duration" {
  count = (var.duration_threshold == null ? 0 : 1)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Duration"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(`aws.lambda.Duration.byFunction`) FROM Metric ${local.filter_subquery} FACET `aws.lambda.FunctionName`"
  }

  critical {
    operator = "above"
    threshold = var.duration_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }

  fill_option = "none"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_timer"
  aggregation_timer = 60

  open_violation_on_expiration = false
  close_violations_on_expiration = false
}
