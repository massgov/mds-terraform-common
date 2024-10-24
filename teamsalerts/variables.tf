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
  default     = null
  description = "URL of incoming webhook. This or `teams_webhook_url_param_arn` is required"
}

variable "teams_webhook_url_param_arn" {
  type        = string
  default     = null
  description = "Parameter Store ARN of incoming webhook URL"
}

variable "teams_webhook_url_param_key" {
  type        = string
  default     = null
  description = "ARN of KMS key used to encrypt/decrypt webhook URL parameter"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "memory_size" {
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
}
