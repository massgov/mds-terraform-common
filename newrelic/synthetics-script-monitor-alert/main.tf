locals {
  policy_id    = coalesce(var.policy_id, try(newrelic_alert_policy.policy[0].id, null))
  script_label = (var.type == "SCRIPT_API" ? "API" : "Scripted Browser")
}

resource "newrelic_alert_policy" "policy" {
  count = (var.policy_id == null ? 1 : 0)

  name                = "${var.name} ${local.script_label} Monitor"
  incident_preference = "PER_POLICY"
}

resource "newrelic_synthetics_script_monitor" "monitor" {
  account_id       = var.account_id
  status           = "ENABLED"
  name             = "${var.name} ${local.script_label} Monitor"
  period           = var.period
  type             = var.type
  locations_public = var.locations

  script               = var.script
  runtime_type         = var.runtime_type
  runtime_type_version = var.runtime_type_version

  # SCRIPT_BROWSER options
  enable_screenshot_on_failure_and_script = var.enable_screenshot_on_failure_and_script
  device_orientation                      = var.device_orientation
  device_type                             = var.device_type

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
    "%s Monitor - More than %d failed requests in %d seconds",
    var.name,
    var.critical_threshold,
    var.critical_threshold_duration
  )

  nrql_query                  = "SELECT filter(count(*), WHERE result = 'FAILED') AS 'Failures' FROM SyntheticCheck WHERE entityGuid IN ('${newrelic_synthetics_script_monitor.monitor.id}') FACET monitorName"
  critical_threshold          = var.critical_threshold
  critical_threshold_duration = var.critical_threshold_duration
  aggregation_window          = var.aggregation_window
  aggregation_method          = "event_flow"
  aggregation_delay           = var.aggregation_delay
  tags                        = var.tags
}
