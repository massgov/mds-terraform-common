########################################################################################################################
# VARIABLES
########################################################################################################################

variable "environments" {
  type        = list(string)
  description = "List of Environments to create resources for multi env. Defaults to [\"\"], if default; will create for 1 environment with no env prefix on resources"
  default     = ["dv", "pr"]
}

variable "prefix" {
  type        = string
  description = "Prefix name used for resources"
}
variable "opensearch_endpoint" {
  type        = string
  description = "Endpoint url"
}
variable "opensearch_arn" {
  type        = string
  description = "Opensearch Severless ARN"
}

variable "lex_botname" {
  type        = string
  description = "Chatbot name"
  default     = "EEC"
}

variable "lex_separate_env" {
  type        = bool
  description = "Should create new bot for each Environments? Defaults to false"
  default     = false
}

variable "guardrail_arns" {
  type        = list(string)
  description = "Provide list of Guardrail Arns if want custom control"
  default     = null
}
variable "cloudwatch_log_retention" {
  type = number
  description = "Number of days to retain logs"
  default = 0
}

variable "guardrail_content_policy" {
  type = list(object({ input_strength = string, output_strength = string, type = string }))

}
variable "guardrail_grounding_policy" {
  type = list(object({ threshold = number, type = string }))

}
variable "guardrail_sensitive_information_policy" {
  type = list(object({ action = string, type = string }))

}
variable "guardrail_word_policy" {
  type    = string

}






