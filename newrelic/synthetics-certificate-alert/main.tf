locals {
  policy_id = coalesce(var.policy_id, try(newrelic_alert_policy.policy[0].id, null))
}

resource "newrelic_alert_policy" "policy" {
  count = (var.policy_id == null ? 1 : 0)

  name                = "${var.name} Monitor"
  incident_preference = "PER_POLICY"
}

resource "newrelic_synthetics_cert_check_monitor" "monitor" {
  account_id             = var.account_id
  status                 = "ENABLED"
  name                   = "${var.name} Certificate Monitor"
  period                 = var.period
  certificate_expiration = var.certificate_expiration
  domain                 = var.domain
  locations_public       = var.locations
  runtime_type           = "NODE_API"
  runtime_type_version   = "16.10"

  dynamic "tag" {
    for_each = var.tags

    content {
      key    = tag.key
      values = try(tolist(tag.value), [tostring(tag.value)])
    }
  }
}

module "alert_condition" {
  source     = "../nrql-alert"
  account_id = var.account_id
  policy_id  = local.policy_id
  name = format(
    "%s Certificate Monitor - Failed %d checks to '%s' in %d seconds",
    var.name,
    var.critical_threshold,
    var.domain,
    var.critical_threshold_duration
  )

  nrql_query                  = "SELECT filter(count(*), WHERE result = 'FAILED') AS 'Failures' FROM SyntheticCheck WHERE entityGuid IN ('${newrelic_synthetics_cert_check_monitor.monitor.id}') FACET monitorName"
  critical_threshold          = var.critical_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = var.aggregation_delay
  tags                        = var.tags
}
