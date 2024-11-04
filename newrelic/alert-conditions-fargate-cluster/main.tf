locals {
  aws_accounts_quoted   = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  cluster_names_quoted = join(", ", formatlist("'%s'", var.filter_cluster_names))
  cluster_names_subquery = length(var.filter_cluster_names) == 0 ? "" : (
    "aws.ecs.containerinsights.ClusterName IN (${local.cluster_names_quoted})"
  )

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.cluster_names_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"
}

module "cpu" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - CPU utilization over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.cpu_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = <<EOF
    SELECT 100 * average(`aws.ecs.containerinsights.CpuUtilized`)/average(`aws.ecs.containerinsights.CpuReserved`)
    FROM Metric
    ${local.filter_subquery}
    FACET aws.ecs.containerinsights.ClusterName
  EOF

  critical_threshold          = var.cpu_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}

module "memory" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Memory usage over %s%% for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.memory_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = <<EOF
    SELECT 100 * average(`aws.ecs.containerinsights.MemoryUtilized`) / average(`aws.ecs.containerinsights.MemoryReserved`)
    FROM Metric
    ${local.filter_subquery}
    FACET aws.ecs.containerinsights.ClusterName
  EOF
  critical_threshold          = var.memory_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}

module "task_count" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Task count under %d for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.task_count_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query = <<EOF
    SELECT average(`aws.ecs.containerinsights.TaskCount`)
    FROM Metric
    ${local.filter_subquery}
    FACET aws.ecs.containerinsights.ClusterName
  EOF
  critical_operator           = "below"
  critical_threshold          = var.task_count_threshold
  critical_threshold_duration = var.task_count_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}