variable "name" {
  type        = string
  description = "A descriptive name to use for created resources"
}

variable "teams_webhook_url" {
  type        = string
  description = "URL of incoming webhook"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "topic_map" {
  description = "The SNS topic(s) to subscribe to, and associated display information"
  type = list(object({
    topic_arn  = string
    human_name = string
    icon_url   = string
  }))
  validation {
    condition     = length(var.topic_map) > 0
    error_message = "Topic map must specify at least one SNS topic to subscribe to."
  }
}
