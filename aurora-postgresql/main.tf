data "aws_caller_identity" "current" {}

locals {
  kms_key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_id

  parameter_group_family = "aurora-postgresql${split(".", var.engine_version)[0]}"

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
