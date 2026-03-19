locals {
  integrations = {
    for name, user_cfg in var.enabled_integrations : name => merge(
      {
        metrics_polling_interval = var.default_metrics_polling_interval
        aws_regions              = var.default_aws_regions
        tag_key                  = var.default_tag_key
        tag_value                = var.default_tag_value
        fetch_tags               = var.default_fetch_tags
        fetch_extended_inventory = var.default_fetch_extended_inventory
      },
      user_cfg
    )
  }
}