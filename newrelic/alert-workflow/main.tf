
# Email Destination
resource "newrelic_notification_destination" "email" {
  count = var.email_enabled ? 1 : 0

  account_id = var.account_id
  name       = "${var.name_prefix}-email-destination"
  type       = "EMAIL"

  property {
    key   = "email"
    value = join(",", var.email_recipients)
  }

  dynamic "auth_basic" {
    for_each = var.email_auth != null ? [var.email_auth] : []
    content {
      user     = auth_basic.value.user
      password = auth_basic.value.password
    }
  }
}

# Email Notification Channel
resource "newrelic_notification_channel" "email" {
  count = var.email_enabled ? 1 : 0

  account_id     = var.account_id
  name           = "${var.name_prefix}-email-channel"
  type           = "EMAIL"
  destination_id = newrelic_notification_destination.email[0].id
  product        = "IINT"

  property {
    key   = "subject"
    value = var.email_subject
  }

  property {
    key   = "customDetailsEmail"
    value = var.email_custom_details
  }
}

# Webhook Destinations
# Only created for channels that do NOT provide an existing destination_id.
# Channels with a pre-existing destination_id reuse it directly.
resource "newrelic_notification_destination" "webhook" {
  for_each = {
    for ch in var.webhook_channels : ch.name => ch
    if ch.destination_id == null || ch.destination_id == ""
  }

  account_id = var.account_id
  name       = "${var.name_prefix}-${each.key}-destination"
  type       = "WEBHOOK"

  property {
    key   = "url"
    value = each.value.url
  }

  dynamic "property" {
    for_each = coalesce(each.value.custom_headers, {})
    content {
      key   = property.key
      value = property.value
    }
  }

  dynamic "auth_basic" {
    for_each = each.value.auth_basic != null ? [each.value.auth_basic] : []
    content {
      user     = auth_basic.value.user
      password = auth_basic.value.password
    }
  }

  dynamic "auth_token" {
    for_each = each.value.auth_token != null ? [each.value.auth_token] : []
    content {
      prefix = auth_token.value.prefix
      token  = auth_token.value.token
    }
  }
}


# Webhook Notification Channels
resource "newrelic_notification_channel" "webhook" {
  for_each = { for ch in var.webhook_channels : ch.name => ch }

  account_id = var.account_id
  name       = coalesce(each.value.channel_name, "${var.name_prefix}-${each.key}-channel")
  type       = "WEBHOOK"
  product    = "IINT"

  # Reuse existing destination or reference the one we just created
  destination_id = (
    each.value.destination_id != null && each.value.destination_id != ""
    ? each.value.destination_id
    : newrelic_notification_destination.webhook[each.key].id
  )

  property {
    key   = "payload"
    value = trimspace(coalesce(each.value.payload, each.value.teams_adaptive_card ? local.teams_adaptive_card_payload : local.default_webhook_payload))
    label = coalesce(each.value.payload_label, "Payload Template")
  }
}

# Workflow
resource "newrelic_workflow" "this" {
  account_id            = var.account_id
  name                  = coalesce(var.workflow_name, "${var.name_prefix}-workflow")
  muting_rules_handling = var.muting_rules_handling
  enabled               = var.workflow_enabled

  issues_filter {
    name = "${var.name_prefix}-filter"
    type = "FILTER"

    dynamic "predicate" {
      for_each = var.issues_filter_predicates
      content {
        attribute = predicate.value.attribute
        operator  = predicate.value.operator
        values    = predicate.value.values
      }
    }
  }

  # Email destination (optional)
  dynamic "destination" {
    for_each = var.email_enabled ? [1] : []
    content {
      channel_id            = newrelic_notification_channel.email[0].id
      notification_triggers = var.notification_triggers
    }
  }

  # One destination block per webhook channel entry
  dynamic "destination" {
    for_each = { for ch in var.webhook_channels : ch.name => ch }
    content {
      channel_id              = newrelic_notification_channel.webhook[destination.key].id
      notification_triggers   = coalesce(destination.value.notification_triggers, var.notification_triggers)
      update_original_message = coalesce(destination.value.update_original_message, false)
    }
  }

  # NRQL enrichments (optional)
  dynamic "enrichments" {
    for_each = length(var.enrichment_nrql_queries) > 0 ? [1] : []
    content {
      dynamic "nrql" {
        for_each = var.enrichment_nrql_queries
        content {
          name = nrql.value.name
          configuration {
            query = nrql.value.query
          }
        }
      }
    }
  }
}
