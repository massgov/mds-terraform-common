resource "aws_bedrock_guardrail" "main" {
  for_each                  = var.guardrail_arns == null ? toset(var.environments) : toset([])
  name                      = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-guardrail"
  blocked_input_messaging   = "Sorry, we cannot help you with this query. Please rephrase and try asking again. This is blocked input."
  blocked_outputs_messaging = "Sorry, we cannot answer this question. Please rephrase and try asking again. This is blocked output."
  description               = "Guardrails for ${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)} Chatbot"

  content_policy_config {
    dynamic "filters_config" {
      for_each = var.guardrail_content_policy
      content {
        input_strength  = lookup(filters_config.value, "input_strength")
        output_strength = lookup(filters_config.value, "output_strength")
        type            = lookup(filters_config.value, "type")
      }
    }
  }
  contextual_grounding_policy_config {
    dynamic "filters_config" {
      for_each = var.guardrail_grounding_policy
      content {
        threshold = lookup(filters_config.value, "threshold")
        type      = lookup(filters_config.value, "type")
      }
    }
  }
  sensitive_information_policy_config {
    dynamic "pii_entities_config" {
      for_each = var.guardrail_sensitive_information_policy
      content {
        action = lookup(pii_entities_config.value, "action")
        type   = lookup(pii_entities_config.value, "type")
      }
    }
  }
  word_policy_config {
    managed_word_lists_config {
      type = var.guardrail_word_policy
    }
  }

  lifecycle {
    ignore_changes = [content_policy_config, contextual_grounding_policy_config, sensitive_information_policy_config, word_policy_config]
  }

}
