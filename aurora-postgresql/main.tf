data "aws_partition" "current" {}

data "aws_caller_identity" "current" {
  count = var.create_kms_key && var.account_id == null ? 1 : 0
}

locals {
  account_id = var.account_id != null ? var.account_id : one(data.aws_caller_identity.current[*].account_id)

  kms_key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_id

  parameter_group_family = "aurora-postgresql${split(".", var.engine_version)[0]}"

  engine_minor_pinned = length(split(".", var.engine_version)) > 1

  instances = merge([
    for name, group in var.instance_groups : {
      for index in range(group.count) :
      "${name}-${index + 1}" => {
        group          = name
        instance_class = coalesce(group.instance_class, var.instance_class)
        promotion_tier = group.promotion_tier
      }
    }
  ]...)

  custom_endpoint_groups = toset([for name, group in var.instance_groups : name if group.custom_endpoint])
}
