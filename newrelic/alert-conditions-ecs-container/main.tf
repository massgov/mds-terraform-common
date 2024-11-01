locals {
  aws_accounts_quoted   = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  container_names_quoted          = join(", ", formatlist("'%s'", var.filter_container_names))
  container_names_subquery        = length(var.filter_container_names) == 0 ? "" : "ecsTaskDefinitionFamily IN (${local.container_names_quoted})"
  memory_container_names_subquery = length(var.filter_container_names) == 0 ? "" : "`aws.ecs.ServiceName` IN (${local.container_names_quoted})"

  filter_subqueries_and        = join(" AND ", compact([local.aws_accounts_subquery, local.container_names_subquery]))
  memory_filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.memory_container_names_subquery]))

  filter_subquery        = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"
  memory_filter_subquery = length(local.memory_filter_subqueries_and) == 0 ? "" : "WHERE (${local.memory_filter_subqueries_and})"

  # This is the maximum aggregation window.
  restart_duration = 7200
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

  nrql_query                  = "SELECT average(`aws.ecs.MemoryUtilization.byService`) FROM Metric ${local.memory_filter_subquery} FACET `aws.ecs.ServiceName`"
  critical_threshold          = var.memory_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}

module "restarts" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - More than %d restarts in %d seconds",
    var.name_prefix,
    var.restart_count_threshold,
    local.restart_duration
  )

  # The `restartCount` value in NR is always 0. But we can mimic restart count
  # by counting the number of unique ARNs for each ECS task.
  nrql_query                  = "SELECT uniqueCount(ecsTaskArn) FROM ContainerSample ${local.filter_subquery} FACET ecsClusterName, ecsContainerName"
  critical_threshold          = var.restart_count_threshold
  critical_threshold_duration = local.restart_duration
  aggregation_window          = local.restart_duration
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}
