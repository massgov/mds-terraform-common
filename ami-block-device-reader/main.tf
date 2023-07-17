# Look up AMI for `include_ami_device_names`
data "aws_ami" "default" {
  filter {
    name = "image-id"
    values = [var.ami]
  }
}

locals {
  exclude_root_list = var.exclude_root_device ? [data.aws_ami.default.root_device_name] : []
  exclude_list = concat(local.exclude_root_list, var.exclude_device_names)

  filter_list = var.device_filter_type == "include" ? var.include_device_names : local.exclude_list

  # If we're including, then `contains` should be true; for excluding, it should
  # be false.
  filter_contains_value = var.device_filter_type == "include" ? true : false

  block_devices = [
    for mapping in data.aws_ami.default.block_device_mappings :
      # flatten object so there isn't a nested "ebs" object
      merge(
         {device_name = mapping.device_name},
         mapping.ebs,
         # overwrite delete_on_termination based on variable
         var.force_delete_on_termination ? { delete_on_termination = true } : {}
      )
      # Only include devices that pass the filter.
      if (contains(local.filter_list, mapping.device_name) == local.filter_contains_value)
  ]
}
