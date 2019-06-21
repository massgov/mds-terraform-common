variable "name" {
  type = string
}

variable "human_name" {
  type        = string
  description = "A human readable name for the function (used in alerting)."
  default     = ""
}

variable "package" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "runtime" {
  type = string
}

variable "timeout" {
  type    = string
  default = 300
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "environment" {
  type = object({
    variables = map(string)
  })
  default = null
}

variable "iam_policy_arns" {
  type        = list(string)
  description = "A list of additional IAM policy ARNs to attach to the function's role."
  default     = []
}

variable "iam_policies" {
  type        = list(string)
  description = "A list of additional IAM policies to attach to the function."
  default     = []
}

variable "schedule" {
  type        = map(string)
  description = "Schedule expressions to use to invoke the lambda regularly"
  default = {
  }
}

variable "tags" {
  type = map(string)
  default = {
  }
}

variable "error_topics" {
  type        = list(string)
  description = "An array of SNS topics to publish notifications to when the function errors out"
  default     = []
}

