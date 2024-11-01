resource "newrelic_nrql_alert_condition" "default" {
  account_id                   = var.account_id
  policy_id                    = var.policy_id
  type                         = var.type
  name                         = var.name
  enabled                      = var.enabled
  violation_time_limit_seconds = var.violation_time_limit_seconds

  nrql {
    query = var.nrql_query
  }

  critical {
    operator              = var.critical_operator
    threshold             = var.critical_threshold
    threshold_duration    = var.critical_threshold_duration
    threshold_occurrences = var.critical_threshold_occurrences
  }

  fill_option         = var.fill_option
  aggregation_window  = var.aggregation_window
  aggregation_method  = var.aggregation_method
  aggregation_delay   = var.aggregation_delay
  aggregation_timer   = var.aggregation_timer
  expiration_duration = var.expiration_duration

  open_violation_on_expiration   = var.open_violation_on_expiration
  close_violations_on_expiration = var.close_violations_on_expiration
}

resource "newrelic_entity_tags" "tags" {
  count = length(var.tags) > 0 ? 1 : 0
  guid  = newrelic_nrql_alert_condition.default.entity_guid

  dynamic "tag" {
    for_each = var.tags

    content {
      key    = tag.key
      values = try(tolist(tag.value), [tostring(tag.value)])
    }
  }
}
