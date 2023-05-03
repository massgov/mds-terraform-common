variable "name_prefix" {
  type        = string
  description = "A name prefix to use for created resources."
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