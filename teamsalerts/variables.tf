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

// variable "sns_topic_count" {
//   type        = string
//   description = "Count of SNS topics to subscribe to (works around TF bug using count on calculated lists)"
// }

variable "topic_map" {
  description = "SNS topic ARNs mapped to human readable names"
  type = list(object({
    topic_arn  = string
    human_name = string
    icon_url   = string
  }))
  default = []
}
