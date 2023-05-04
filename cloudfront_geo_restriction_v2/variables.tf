variable "name_prefix" {
  type        = string
  description = "A name prefix to use for created resources."
  validation {
    condition = can(regex("^[a-zA-Z0-9-]*[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "Prefix should only contain alphanumeric characters and (optionally) dashes. It must not end in a dash."
  }
}

variable "enable_cloudwatch_metrics" {
  type        = bool
  description = "When true, WAF will report metrics (e.g. BlockedRequests) to Cloudwatch once per minute"
  default = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the WAF ACL"
  default = {
  }
}