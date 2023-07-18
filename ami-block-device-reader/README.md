AMI Block Device Reader
===============

This module queries an AMI and outputs a (filtered) list of the block devices it defines. Which devices are included in the output can be specified by the `device_filter_type`, `device_names`, and `exclude_root_device` variables.

- When `device_filter_type` is `include`, the output only contains the devices whose names are in the `device_names` list.
- When `device_filter_type` is `exclude`, the output contains all devices except:
  - Devices whose name is *not* in the `device_names` list.
  - The root device (if `exclude_root_device` is `true`).

Additionally, if the `force_delete_on_termination` variable is set to `true`, the devices will all have the `delete_on_termination` property set to `true`.



An example of using this module:

```terraform
module "ami_devices" {
  source                      = "github.com/massgov/mds-terraform-common//aws-block-device-reader?ref=1.0.57"
  ami                         = "my-ami123"

  # Only include the "/dev/sdf" device
  device_filter_type          = "include"
  include_device_names        = ["/dev/sdf"]

  # Set delete_on_termination to `true`.
  force_delete_on_termination = true
}


resource "aws_launch_template" "default" {
  # ...

  # Redefine the block devices from the AMI in our launch template.
  dynamic "block_device_mappings" {
    for_each = module.ami_devices.ami_devices

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted = block_device_mappings.value.encrypted
        iops = block_device_mappings.value.iops
        snapshot_id = block_device_mappings.value.snapshot_id
        throughput = block_device_mappings.value.throughput
        volume_size = block_device_mappings.value.volume_size
        volume_type = block_device_mappings.value.volume_type
      }
    }
  }

  # ...
```

