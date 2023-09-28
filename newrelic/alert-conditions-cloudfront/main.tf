locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  distribution_names_quoted = join(", ", formatlist("'%s'", var.filter_distribution_names))
  distribution_names_subquery = length(var.filter_distribution_names) == 0 ? "" : "entity.name IN (${local.distribution_names_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.distribution_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

}

resource "newrelic_nrql_alert_condition" "error_rate" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Error Rate"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.cloudfront.TotalErrorRate) FROM Metric ${local.filter_subquery} FACET entity.name"
  }

  critical {
    operator = "above"
    threshold = var.error_rate_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_flow"
  aggregation_delay = 120

  open_violation_on_expiration = false
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "throughput" {
  count = (var.throughput_enabled ? 1 : 0)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Throughput"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.cloudfront.Requests) FROM Metric ${local.filter_subquery} FACET entity.name"
  }

  critical {
    operator = "below"
    threshold = var.throughput_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_flow"
  aggregation_delay = 120

  open_violation_on_expiration = false
  close_violations_on_expiration = false
}
