variable "name" {
  type = string
}

variable "human_name" {
  type        = string
  description = "A human readable name for the function (used in alerting). This name must be unique across environments!"
  default     = ""
}

variable "timeout" {
  type    = string
  default = 300
}

variable "memory_size" {
  type        = string
  default     = 128
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

variable "environment_vars" {
  type    = map(string)
  default = {}
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
    monday_4_30 = "cron(30 4 * * 1)"
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

variable "allowed_points_parameter" {
  type    = string
  default = "/infrastructure/entrypoint-monitoring/allowed-points"
}

variable "min_log_level" {
  type    = string
  default = "log"
}

variable "report_topic_arn" {
  type        = string
  description = "ARN of the SNS topic the lambda reports to about the found orphan entrypoints."
}
