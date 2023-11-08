variable "name_prefix" {
  type        = string
  description = "A name prefix to use for created resources."
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "Prefix should only contain alphanumeric characters and (optionally) dashes. It must not end in a dash."
  }
}

variable "newrelic_api_url" {
  type        = string
  description = "The New Relic api url. The default is the US url."
  default     = "https://aws-api.newrelic.com/cloudwatch-metrics/v1"
}

variable "newrelic_access_key" {
  type        = string
  description = "The new relic access key."
}

variable "newrelic_aws_account_name" {
  type        = string
  description = "Nickname for AWS account in New Relic."
}

variable "newrelic_account_id" {
  type        = string
  description = "The account number for the New Relic account."
}

variable "buffering_size" {
  type        = number
  description = "Buffer size for http configuration. See kinesis_firehose_delivery_stream.http_endpoint_configuration.buffering_size."
  default     = 1 # Default recommended by New Relic
}

variable "buffering_interval" {
  type        = number
  description = "Buffer interval for http configuration. See kinesis_firehose_delivery_stream.http_endpoint_configuration.buffering_interval."
  default     = 60 # Default recommended by New Relic
}

variable "retry_duration" {
  type        = number
  description = "Retry duration for http configuration. See kinesis_firehose_delivery_stream.http_endpoint_configuration.retry_duration."
  default     = 60 # Default recommended by New Relic
}

variable "include_filters" {
  type        = list(object({
                  namespace = string,
                  metric_names = list(string)
                }))
  description = "List of metrics to include. See aws_cloudwatch_metric_stream.include_filter. Note - empty metric_names list will include all metrics."
}

variable "tags" {
  type = map(string)
  default = {}
}
