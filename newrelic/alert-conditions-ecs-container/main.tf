locals {
  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  container_names_quoted = join(", ", formatlist("'%s'", var.filter_container_names))
  container_names_subquery = length(var.filter_container_names) == 0 ? "" : "ecsTaskDefinitionFamily IN (${local.container_names_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.container_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

}

resource "newrelic_nrql_alert_condition" "memory" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Memory"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(memoryUsageLimitPercent) FROM ContainerSample ${local.filter_subquery} FACET ecsTaskDefinitionFamily"
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

resource "newrelic_nrql_alert_condition" "restarts" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Restarts"
  enabled = true
  violation_time_limit_seconds = 259200

  # The `restartCount` value in NR is always 0. But we can mimic restart count
  # by counting the number of unique ARNs for each ECS task.
  nrql {
    query = "SELECT uniqueCount(ecsTaskArn) FROM ContainerSample ${local.filter_subquery} FACET ecsTaskDefinitionFamily"
  }

  critical {
    operator = "above"
    threshold = 5
    threshold_duration = 3600
    threshold_occurrences = "all"
  }

  fill_option = "none"

  # This is the maximum aggregation window.
  aggregation_window = 7200
  aggregation_method = "event_flow"
  aggregation_delay = 120
  slide_by = 3600
}
