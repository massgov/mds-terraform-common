# ─────────────────────────────────────────────────────────────────────────────
# Required
# ─────────────────────────────────────────────────────────────────────────────

variable "account_id" {
  description = "New Relic account ID."
  type        = number
}

variable "name_prefix" {
  description = "Prefix applied to all auto-generated resource names (e.g. 'ds-ssr-prod')."
  type        = string
}

# ─────────────────────────────────────────────────────────────────────────────
# Workflow
# ─────────────────────────────────────────────────────────────────────────────

variable "workflow_name" {
  description = "Explicit workflow name. Defaults to '<name_prefix>-workflow' if not set."
  type        = string
  default     = null
}

variable "workflow_enabled" {
  description = "Enable or disable the workflow."
  type        = bool
  default     = true
}

variable "muting_rules_handling" {
  description = "How muting rules affect the workflow. Options: DONT_NOTIFY_FULLY_MUTED_ISSUES, DONT_NOTIFY_FULLY_OR_PARTIALLY_MUTED_ISSUES, NOTIFY_ALL_ISSUES."
  type        = string
  default     = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  validation {
    condition = contains([
      "DONT_NOTIFY_FULLY_MUTED_ISSUES",
      "DONT_NOTIFY_FULLY_OR_PARTIALLY_MUTED_ISSUES",
      "NOTIFY_ALL_ISSUES"
    ], var.muting_rules_handling)
    error_message = "Invalid muting_rules_handling value."
  }
}

variable "notification_triggers" {
  description = "Default notification triggers for all channels (can be overridden per channel). Options: ACTIVATED, ACKNOWLEDGED, PRIORITY_CHANGED, CLOSED, INVESTIGATING, OTHER_UPDATES."
  type        = list(string)
  default     = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issues Filter
# ─────────────────────────────────────────────────────────────────────────────

variable "issues_filter_predicates" {
  description = <<-EOT
    List of filter predicates for the workflow. Each predicate:
      attribute (string) — e.g. "labels.policyIds", "priority", "tag.team"
      operator  (string) — EQUAL, NOT, CONTAINS, NOT_CONTAINS, STARTS_WITH, ENDS_WITH, LESS_THAN, GREATER_THAN
      values    (list)   — one or more match values
  EOT
  type = list(object({
    attribute = string
    operator  = string
    values    = list(string)
  }))
  default = []
}

# ─────────────────────────────────────────────────────────────────────────────
# Webhook Channels
# Pass one object per channel. The module creates one destination + channel
# resource per entry (unless destination_id is supplied, in which case it
# reuses the existing destination).
# ─────────────────────────────────────────────────────────────────────────────

variable "webhook_channels" {
  description = <<-EOT
    List of webhook channel configurations. Fields:

    REQUIRED (if destination_id is omitted):
      name         (string) — unique key used in resource names
      url          (string) — webhook endpoint URL

    OPTIONAL:
      channel_name          (string)      — override the channel display name
      destination_id        (string)      — reuse an existing New Relic destination UUID
      payload               (string)      — JSON payload template; defaults to built-in if omitted
      payload_label         (string)      — label shown on the payload property
      source_label          (string)      — value for a "source" property (e.g. "terraform")
      custom_headers        (map(string)) — extra HTTP headers sent with the request
      auth_basic            (object)      — { user, password }
      auth_token            (object)      — { prefix, token }  e.g. { prefix="Bearer", token="..." }
      notification_triggers (list(string))— per-channel override; falls back to var.notification_triggers
      update_original_message (bool)      — update the original Teams/Slack message on state change
      teams_adaptive_card   (bool)      — use the newer Adaptive Card format for MS Teams instead of the legacy MessageCard (only applicable if payload is omitted or uses the built-in Teams template)
  EOT
  type = list(object({
    name                     = string
    url                      = optional(string, "")
    channel_name             = optional(string, null)
    destination_id           = optional(string, null)
    payload                  = optional(string, null)
    payload_label            = optional(string, null)
    source_label             = optional(string, null)
    custom_headers           = optional(map(string), {})
    auth_basic = optional(object({
      user     = string
      password = string
    }), null)
    auth_token = optional(object({
      prefix = string
      token  = string
    }), null)
    notification_triggers   = optional(list(string), null)
    update_original_message = optional(bool, false)
    teams_adaptive_card     = optional(bool, false)
  }))
  default = []
}

# ─────────────────────────────────────────────────────────────────────────────
# Email
# ─────────────────────────────────────────────────────────────────────────────

variable "email_enabled" {
  description = "Enable email destination and channel."
  type        = bool
  default     = false
}

variable "email_recipients" {
  description = "List of recipient email addresses."
  type        = list(string)
  default     = []
}

variable "email_subject" {
  description = "Email subject. Supports New Relic template variables."
  type        = string
  default     = "New Relic Alert: {{issueTitle}}"
}

variable "email_custom_details" {
  description = "Email body. Supports New Relic template variables."
  type        = string
  default     = "Issue URL: {{issuePageUrl}}\nPriority: {{priority}}\nState: {{state}}"
}

variable "email_auth" {
  description = "Optional basic auth for the email destination."
  type = object({
    user     = string
    password = string
  })
  default   = null
  sensitive = true
}

# ─────────────────────────────────────────────────────────────────────────────
# Enrichments
# ─────────────────────────────────────────────────────────────────────────────

variable "enrichment_nrql_queries" {
  description = "Optional NRQL enrichments attached to every notification."
  type = list(object({
    name  = string
    query = string
  }))
  default = []
}
