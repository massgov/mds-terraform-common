# Look up AMI for `include_ami_device_names`
data "aws_ami" "default" {
  filter {
    name   = "image-id"
    values = [var.ami]
  }
}

locals {
  # If the filter type is `exclude` and `exclude_root_device` is set, add the root device name to the list
  exclude_root_list = var.device_filter_type == "exclude" && var.exclude_root_device ? [data.aws_ami.default.root_device_name] : []

  filter_list = concat(local.exclude_root_list, var.device_names)

  # If the filter type is `include`, then we want to include the volume only if it is contained in the list.
  # If the filter type is `exclude`, then we want to include the volume only if it is NOT contained in the list.
  filter_contains_value = var.device_filter_type == "include" ? true : false

  block_devices = [
    for mapping in data.aws_ami.default.block_device_mappings :
    # flatten object so there isn't a nested "ebs" object
    merge(
      { device_name = mapping.device_name },
      mapping.ebs,
      # overwrite delete_on_termination based on variable
      var.force_delete_on_termination ? { delete_on_termination = true } : {}
    )
    # Only include devices that pass the filter.
    if(contains(local.filter_list, mapping.device_name) == local.filter_contains_value)
  ]
}
