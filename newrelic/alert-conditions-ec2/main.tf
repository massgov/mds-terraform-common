locals {
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

}

resource "newrelic_nrql_alert_condition" "alert" {
  account_id = var.account_id
  policy_id = var.alert_policy_id
  type = "static"
  name = "${var.name_prefix} - CPU"
  enabled = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT average(aws.ec2.CPUUtilization) FROM Metric ${local.filter_subquery} FACET aws.ec2.InstanceId"
  }

  critical {
    operator = "above"
    threshold = var.critical_threshold
    threshold_duration = var.critical_threshold_duration
    threshold_occurrences = "all"
  }
  fill_option = "none"
  aggregation_window = var.aggregation_window
  aggregation_method = "event_flow"
  aggregation_delay = 120
  expiration_duration = 600
  open_violation_on_expiration = var.open_violation_on_expiration
  close_violations_on_expiration = false
}
