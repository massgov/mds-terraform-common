########################################################################################################################
# VARIABLES
########################################################################################################################

variable "environments" {
  type        = list(string)
  description = "List of Environments to create resources for multi env. Defaults to [\"\"], if default; will create for 1 environment with no env prefix on resources"
  default     = [""]
}

variable "prefix" {
  type        = string
  description = "Prefix name used for resources"
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

variable "guardrail_content_policy" {
  type = list(object({ input_strength = string, output_strength = string, type = string }))
  default = [
    {
      "input_strength"  = "MEDIUM"
      "output_strength" = "LOW"
      "type"            = "SEXUAL"
    },
    {
      "input_strength"  = "MEDIUM"
      "output_strength" = "LOW"
      "type"            = "SEXUAL"
    },
    {
      input_strength  = "MEDIUM"
      output_strength = "LOW"
      type            = "SEXUAL"
    },
    {
      input_strength  = "MEDIUM"
      output_strength = "LOW"
      type            = "HATE"
    },
    {
      input_strength  = "MEDIUM"
      output_strength = "LOW"
      type            = "VIOLENCE"
    },
    {
      input_strength  = "MEDIUM"
      output_strength = "LOW"
      type            = "INSULTS"
    },
    {
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
      type            = "MISCONDUCT"
    },
    {
      input_strength  = "HIGH"
      output_strength = "NONE"
      type            = "PROMPT_ATTACK"
    }
  ]
}
variable "guardrail_grounding_policy" {
  type = list(object({ threshold = number, type = string }))
  default = [
    {
      threshold = 0.7
      type      = "GROUNDING"
    },
    {
      threshold = 0.7
      type      = "RELEVANCE"
  }]
}
variable "guardrail_sensitive_information_policy" {
  type = list(object({ action = string, type = string }))
  default = [
    {
      action = "BLOCK"
      type   = "EMAIL"
    },
    {
      action = "BLOCK"
      type   = "USERNAME"
    },
    {
      action = "BLOCK"
      type   = "PASSWORD"
    },
    {
      action = "BLOCK"
      type   = "DRIVER_ID"
    },
    {
      action = "BLOCK"
      type   = "LICENSE_PLATE"
    },
    {
      action = "BLOCK"
      type   = "VEHICLE_IDENTIFICATION_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "CREDIT_DEBIT_CARD_CVV"
    },
    {
      action = "BLOCK"
      type   = "CREDIT_DEBIT_CARD_EXPIRY"
    },
    {
      action = "BLOCK"
      type   = "CREDIT_DEBIT_CARD_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "PIN"
    },
    {
      action = "BLOCK"
      type   = "INTERNATIONAL_BANK_ACCOUNT_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "SWIFT_CODE"
    },
    {
      action = "BLOCK"
      type   = "IP_ADDRESS"
    },
    {
      action = "BLOCK"
      type   = "MAC_ADDRESS"
    },
    {
      action = "BLOCK"
      type   = "AWS_ACCESS_KEY"
    },
    {
      action = "BLOCK"
      type   = "AWS_SECRET_KEY"
    },
    {
      action = "BLOCK"
      type   = "US_PASSPORT_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "US_SOCIAL_SECURITY_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "US_BANK_ACCOUNT_NUMBER"
    },
    {
      action = "BLOCK"
      type   = "US_BANK_ROUTING_NUMBER"
  }]
}
variable "guardrail_word_policy" {
  type    = string
  default = "PROFANITY"
}






