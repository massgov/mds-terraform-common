output "workflow_id" {
  description = "ID of the created New Relic workflow."
  value       = newrelic_workflow.this.id
}

output "workflow_name" {
  description = "Name of the created New Relic workflow."
  value       = newrelic_workflow.this.name
}

output "email_destination_id" {
  description = "ID of the email destination (null if email not enabled)."
  value       = var.email_enabled ? newrelic_notification_destination.email[0].id : null
}

output "email_channel_id" {
  description = "ID of the email notification channel (null if email not enabled)."
  value       = var.email_enabled ? newrelic_notification_channel.email[0].id : null
}

output "webhook_destination_ids" {
  description = "Map of webhook channel name → destination ID (only for newly created destinations)."
  value       = { for k, v in newrelic_notification_destination.webhook : k => v.id }
}

output "webhook_channel_ids" {
  description = "Map of webhook channel name → notification channel ID."
  value       = { for k, v in newrelic_notification_channel.webhook : k => v.id }
}
