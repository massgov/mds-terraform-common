variable "name" {
  type        = string
  description = "A name to use for created resources. Must be unique among lambda function names"
}

variable "human_name" {
  type        = string
  description = "A human-readable name for the lambda"
}

variable "teams_webhook_url" {
  type        = string
  description = "URL of incoming webhook"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable memory_size {
  type        = number
  description = "Amount of memory in MB the lambda can use at runtime."
  default     = 128
}

variable "timeout" {
  type        = number
  description = "The amount of time the lambda has to run in seconds"
  default     = 30
}

variable "error_topics" {
  type        = list(string)
  description = "An array of SNS topics to publish notifications to when the function errors out"
  default     = []
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
