variable "name" {
  type = string
}

variable "human_name" {
  type        = string
  description = "A human readable name for the function (used in alerting). This name must be unique across environments!"
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

variable "publish" {
  type = bool
  default = true
}

variable "timeout" {
  type    = string
  default = 300
}

variable "memory_size" {
  type = string
  default = 128
  description = "The memory limit for the Lambda Function"
}

variable "ephemeral_storage_size" {
  type = string
  default = 512
  description = "The amount of ephemeral storage to provision for the Lambda"
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "layers" {
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

