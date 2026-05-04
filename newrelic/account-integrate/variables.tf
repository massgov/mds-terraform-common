variable "name_prefix" {
  type        = string
  description = "A name prefix to use for created resources."
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "Prefix should only contain alphanumeric characters and (optionally) dashes. It must not end in a dash."
  }
}

variable "aws_account_name" {
  type        = string
  description = "The account name for the AWS account."
}

variable "newrelic_account_id" {
  type        = string
  description = "The account number for the New Relic account."
}

variable "newrelic_iam_role_arn" {
  type        = string
  description = "Previous created Iam Role for New Relic Integration"
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "default_metrics_polling_interval" {
  type    = number
  default = 300
}

variable "default_aws_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "default_tag_key" {
  type    = string
  default = "test"
}

variable "default_tag_value" {
  type    = string
  default = null
}

variable "default_fetch_tags" {
  type    = bool
  default = true
}

variable "default_fetch_extended_inventory" {
  type    = bool
  default = false
}

variable "enabled_integrations" {
  description = <<EOT
List of available services:
    - billing
    - health
    - trusted_advisor
    - cloudtrail
    - vpc
    - x_ray
    - s3
    - doc_db
    - sqs
    - ebs
    - alb
    - elasticache
    - api_gateway
    - auto_scaling
    - aws_app_sync
    - aws_athena
    - aws_cognito
    - aws_connect
    - aws_direct_connect
    - aws_fsx
    - aws_glue
    - aws_kinesis_analytics
    - aws_media_convert
    - aws_media_package_vod
    - aws_mq
    - aws_msk
    - aws_neptune
    - aws_qldb
    - aws_route53resolver
    - aws_states
    - aws_transit_gateway
    - aws_waf
    - aws_wafv2
    - cloudfront
    - dynamodb
    - ec2
    - ecs
    - efs
    - elasticbeanstalk
    - elasticsearch
    - elb
    - emr
    - iam
    - iot
    - kinesis
    - kinesis_firehose
    - lambda
    - rds
    - redshift
    - route53
    - ses
    - sns
    - security_hub
EOT
  type = map(object({
    metrics_polling_interval = optional(number)
    aws_regions              = optional(list(string))

    tag_key   = optional(string)
    tag_value = optional(string)

    fetch_tags               = optional(bool)
    fetch_extended_inventory = optional(bool)

    queue_prefixes         = optional(list(string))
    load_balancer_prefixes = optional(list(string))
    stage_prefixes         = optional(list(string))

    fetch_nat_gateway     = optional(bool)
    fetch_vpn             = optional(bool)
    fetch_shards          = optional(bool)
    fetch_nodes           = optional(bool)
    fetch_ip_addresses    = optional(bool)
    duplicate_ec2_tags    = optional(bool)
    fetch_lambdas_at_edge = optional(bool)
  }))
  default = {}
}