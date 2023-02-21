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
    monday_4_30 = "cron(30 4 ? * 1 *)"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "error_topics" {
  type        = list(string)
  description = "An array of SNS topics to publish notifications to when the function errors out"
  default     = []
}

variable "min_log_level" {
  type        = string
  description = "The logging level. Accepted values are 'debug', 'log', or 'error'."
  default     = "error"
}

variable "ssm_parameter_prefix" {
  type        = string
  description = "The name prefix of the SSM parameters used for runtime configuration. It must have no trailing slash!"
  default     = "/infrastructure/dependabot-to-teams-webhook"
}

variable "send_to_teams" {
  type        = bool
  description = "Whether to actually send the message to the Teams channel or just log the payload that could be sent to Teams."
  default     = false
}
