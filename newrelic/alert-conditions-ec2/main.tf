locals {
  metric_name = (var.use_agent_metrics ? "cpuPercent" : "aws.ec2.CPUUtilization")
  table_name  = (var.use_agent_metrics ? "SystemSample" : "Metric")

  aws_accounts_quoted   = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  instance_names_quoted   = join(", ", formatlist("'%s'", var.filter_instance_names))
  instance_names_subquery = length(var.filter_instance_names) == 0 ? "" : "tags.Name IN (${local.instance_names_quoted})"

  asg_names_quoted   = join(", ", formatlist("'%s'", var.filter_asg_names))
  asg_names_subquery = length(var.filter_asg_names) == 0 ? "" : "`tags.aws:autoscaling:groupName` IN (${local.asg_names_quoted})"

  exclude_mount_points_quoted   = join(", ", formatlist("'%s'", var.filter_exclude_mount_points))
  exclude_mount_points_subquery = length(var.filter_exclude_mount_points) == 0 ? "" : "mountPoint NOT IN (${local.exclude_mount_points_quoted})"

  filter_subqueries    = compact([local.instance_names_subquery, local.asg_names_subquery])
  filter_subqueries_or = join("", ["(", join(" OR ", local.filter_subqueries), ")"])

  filter_subqueries_and         = join(" AND ", compact([local.aws_accounts_subquery, local.filter_subqueries_or]))
  storage_filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.filter_subqueries_or, local.exclude_mount_points_subquery]))

  filter_subquery         = length(local.filter_subqueries) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"
  storage_filter_subquery = local.storage_filter_subqueries_and == "" ? "" : "WHERE (${local.storage_filter_subqueries_and})"

  default_window   = (var.use_agent_metrics ? 60 : 300)
  default_timer    = local.default_window
  default_duration = (var.use_agent_metrics ? 120 : 300)

  window   = var.aggregation_window == null ? local.default_window : var.aggregation_window
  timer    = local.window
  duration = var.critical_threshold_duration == null ? local.default_duration : var.critical_threshold_duration
}


module "cpu" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - CPU utilization over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.cpu_threshold), "/\\.0+$/", ""),
    local.duration
  )

  nrql_query                  = "SELECT average(${local.metric_name}) FROM ${local.table_name} ${local.filter_subquery} FACET aws.ec2.InstanceId"
  critical_threshold          = var.cpu_threshold
  critical_threshold_duration = local.duration
  aggregation_window          = local.window
  aggregation_method          = "event_timer"
  aggregation_timer           = local.timer
  tags                        = var.tags
}

module "loss_of_signal" {
  count  = (var.alert_loss_of_signal ? 1 : 0)
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - No metrics reported for at least %d seconds",
    var.name_prefix,
    var.loss_of_signal_time
  )

  nrql_query = "SELECT average(${local.metric_name}) FROM ${local.table_name} ${local.filter_subquery} FACET tags.Name"
  # This should never actually trigger, since CPUUtilization is a percent.
  # We don't care about this condition, we're just using this alert to use
  # the "open_violation_on_expiration" parameter to detect signal loss (by
  # instance name instead of instance id). Otherwise, every instance refresh
  # causes alerts/an "incident" in NR.
  critical_threshold           = 101
  critical_threshold_duration  = local.duration
  aggregation_window           = local.window
  aggregation_method           = "event_timer"
  aggregation_timer            = local.timer
  expiration_duration          = var.loss_of_signal_time
  open_violation_on_expiration = true
  tags                         = var.tags
}

module "memory" {
  count  = (var.use_agent_metrics ? 1 : 0)
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Memory usage over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.memory_threshold), "/\\.0+$/", ""),
    local.duration
  )

  nrql_query                  = "SELECT average(memoryUsedPercent) FROM SystemSample ${local.filter_subquery} FACET aws.ec2.InstanceId"
  critical_threshold          = var.memory_threshold
  critical_threshold_duration = local.duration
  aggregation_method          = "event_timer"
  aggregation_window          = local.window
  aggregation_timer           = local.timer
  tags                        = var.tags
}

module "storage" {
  count  = (var.use_agent_metrics ? 1 : 0)
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Storage usage over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.storage_threshold), "/\\.0+$/", ""),
    local.duration
  )

  nrql_query                  = "SELECT average(diskUsedPercent) FROM StorageSample ${local.storage_filter_subquery} FACET `tags.Name`, mountPoint"
  critical_threshold          = var.storage_threshold
  critical_threshold_duration = local.duration
  aggregation_method          = "event_timer"
  aggregation_window          = local.window
  aggregation_timer           = local.timer
  tags                        = var.tags
}
