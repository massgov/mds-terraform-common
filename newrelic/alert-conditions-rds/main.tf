locals {
  aws_accounts_quoted   = join(", ", formatlist("'%s'", var.filter_aws_accounts))
  aws_accounts_subquery = length(var.filter_aws_accounts) == 0 ? "" : "aws.accountId IN (${local.aws_accounts_quoted})"

  db_identifiers_quoted   = join(", ", formatlist("'%s'", var.filter_db_identifiers))
  db_identifiers_subquery = length(var.filter_db_identifiers) == 0 ? "" : "`aws.rds.DBInstanceIdentifier` IN (${local.db_identifiers_quoted})"

  filter_subqueries_and = join(" AND ", compact([local.aws_accounts_subquery, local.db_identifiers_subquery]))

  filter_subquery = length(local.filter_subqueries_and) == 0 ? "" : "WHERE (${local.filter_subqueries_and})"

  allocated_space_bytes = var.allocated_space_gb * pow(1024, 3)
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

  nrql_query                  = "SELECT average(`aws.rds.CPUUtilization`) FROM Metric ${local.filter_subquery} FACET `aws.rds.DBInstanceIdentifier`"
  critical_threshold          = var.cpu_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}

module "free_space" {
  source = "../nrql-alert"

  account_id = var.account_id
  policy_id  = var.alert_policy_id
  name = format(
    "%s - Less than %s%% space free for at least %d seconds",
    var.name_prefix,
    replace(format("%f", var.free_space_threshold), "/\\.0+$/", ""),
    var.critical_threshold_duration
  )

  nrql_query                  = "SELECT (average(`aws.rds.FreeStorageSpace`) / ${local.allocated_space_bytes}) * 100 AS `FreeStoragePercent` FROM Metric ${local.filter_subquery} FACET `aws.rds.DBInstanceIdentifier`"
  critical_operator           = "below"
  critical_threshold          = var.free_space_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = 120
  tags                        = var.tags
}
