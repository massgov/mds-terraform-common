locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  cluster_names_quoted = join(", ", formatlist("'%s'", var.filter_cluster_names))
  cluster_names_subquery = length(var.filter_cluster_names) == 0 ? "" : "aws.ecs.ClusterName IN (${local.cluster_names_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.cluster_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

}

resource "newrelic_nrql_alert_condition" "cpu" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - CPU"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.ecs.CPUUtilization.byCluster) FROM Metric ${local.filter_subquery} FACET aws.ecs.ClusterName"
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

resource "newrelic_nrql_alert_condition" "memory" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Memory"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.ecs.MemoryUtilization.byCluster) FROM Metric ${local.filter_subquery} FACET aws.ecs.ClusterName"
  }

  critical {
    operator = "above"
    threshold = var.memory_threshold
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
