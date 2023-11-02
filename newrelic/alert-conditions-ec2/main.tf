locals {
  metric_name = (var.use_agent_metrics ? "cpuPercent" : "aws.ec2.CPUUtilization")
  table_name = (var.use_agent_metrics ? "SystemSample" : "Metric")

  aws_accounts_quoted = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  instance_names_quoted = join(", ", formatlist("'%s'", var.filter_instance_names))
  instance_names_subquery = length(var.filter_instance_names) == 0 ? "" : "tags.Name IN (${local.instance_names_quoted})"

  asg_names_quoted = join(", ", formatlist("'%s'", var.filter_asg_names))
  asg_names_subquery = length(var.filter_asg_names) == 0 ? "" : "`tags.aws:autoscaling:groupName` IN (${local.asg_names_quoted})"

  filter_subqueries = compact([local.instance_names_subquery, local.asg_names_subquery])
  filter_subqueries_or = join("", ["(", join(" OR ", local.filter_subqueries), ")"])

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.filter_subqueries_or]))

  filter_subquery = length(local.filter_subqueries) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

  default_window = (var.use_agent_metrics ? 60 : 300)
  default_timer = local.default_window
  default_duration = (var.use_agent_metrics ? 120 : 300)

  window = var.aggregation_window == null ? local.default_window : var.aggregation_window
  timer = local.window
  duration = var.critical_threshold_duration == null ? local.default_duration : var.critical_threshold_duration
}

resource "newrelic_nrql_alert_condition" "alert" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - CPU"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(${local.metric_name}) FROM ${local.table_name} ${local.filter_subquery} FACET aws.ec2.InstanceId"
  }

  critical {
    operator = "above"
    threshold = var.critical_threshold
    threshold_duration = local.duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = local.window
  aggregation_method = "event_timer"
  aggregation_timer = local.timer
  expiration_duration = 600
  open_violation_on_expiration = false
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "loss_of_signal" {
  count = (var.alert_loss_of_signal ? 1 : 0)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Loss of Signal"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.ec2.CPUUtilization) FROM Metric ${local.filter_subquery} FACET tags.Name"
  }

  critical {
    operator = "above"
    # This should never actually trigger, since CPUUtilization is a percent.
    # We don't care about this condition, we're just using this alert to use
    # the "open_violation_on_expiration" parameter to detect signal loss (by
    # instance name instead of instance id). Otherwise, every instance refresh
    # causes alerts/an "incident" in NR.
    threshold = 101
    threshold_duration = local.duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = local.window
  aggregation_method = "event_timer"
  aggregation_timer = local.timer
  expiration_duration = 600
  open_violation_on_expiration = true
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "memory" {
  count = (var.use_agent_metrics ? 1 : 0)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Memory"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(memoryUsedPercent) FROM SystemSample ${local.filter_subquery} FACET aws.ec2.InstanceId"
  }

  critical {
    operator = "above"
    threshold = var.critical_threshold
    threshold_duration = local.duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = local.window
  aggregation_method = "event_timer"
  aggregation_timer = local.timer
  expiration_duration = 600
  open_violation_on_expiration = false
  close_violations_on_expiration = false
}

resource "newrelic_nrql_alert_condition" "storage" {
  count = (var.use_agent_metrics ? 1 : 0)

  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - Storage"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(diskUsedPercent) FROM StorageSample ${local.filter_subquery} FACET `tags.Name`, mountPoint"
  }

  critical {
    operator = "above"
    threshold = var.critical_threshold
    threshold_duration = local.duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = local.window
  aggregation_method = "event_timer"
  aggregation_timer = local.timer
  expiration_duration = 600
  open_violation_on_expiration = false
  close_violations_on_expiration = false
}
