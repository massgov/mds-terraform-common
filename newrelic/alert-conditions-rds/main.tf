locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  db_identifiers_quoted = join(", ", formatlist("'%s'", var.filter_db_identifiers))
  db_identifiers_subquery = length(var.filter_db_identifiers) == 0 ? "" : "`aws.rds.DBInstanceIdentifier` IN (${local.db_identifiers_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.db_identifiers_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

  allocated_space_bytes = var.allocated_space_gb * pow(1024, 3)
}

resource "newrelic_nrql_alert_condition" "cpu" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - CPU"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(`aws.rds.CPUUtilization`) FROM Metric ${local.filter_subquery} FACET `aws.rds.DBInstanceIdentifier`"
  }

  critical {
    operator = "above"
    threshold = var.cpu_threshold
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

resource "newrelic_nrql_alert_condition" "free_space" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Free Space"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT (average(`aws.rds.FreeStorageSpace`) / ${local.allocated_space_bytes}) * 100 AS `FreeStoragePercent` FROM Metric ${local.filter_subquery} FACET `aws.rds.DBInstanceIdentifier`"
  }

  critical {
    operator = "below"
    threshold = var.free_space_threshold
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
