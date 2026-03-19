locals {
  integrations = {
    for name, user_cfg in var.enabled_integrations : name => {
      metrics_polling_interval = coalesce(lookup(user_cfg, "metrics_polling_interval", null), var.default_metrics_polling_interval)
      aws_regions              = coalesce(lookup(user_cfg, "aws_regions", null), var.default_aws_regions)
      # tag_key = coalesce(lookup(user_cfg, "tag_key", null), var.default_tag_key)
      # tag_value = coalesce(lookup(user_cfg, "tag_value", null), var.default_tag_value)
      fetch_tags               = coalesce(lookup(user_cfg, "fetch_tags", null), var.default_fetch_tags)
      fetch_extended_inventory = coalesce(lookup(user_cfg, "fetch_extended_inventory", null), var.default_fetch_extended_inventory)
    }
  }
}