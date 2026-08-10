check "engine_version" {
  assert {
    condition     = !(local.engine_minor_pinned && var.auto_minor_version_upgrade)
    error_message = "${var.name} pins engine_version to ${var.engine_version} while auto_minor_version_upgrade is enabled; once AWS applies a minor upgrade the configured version becomes a downgrade that cannot be applied. Pin the major version alone, or disable auto_minor_version_upgrade."
  }
}

check "encryption" {
  assert {
    condition     = !(var.create_kms_key && var.kms_key_id != null)
    error_message = "Both create_kms_key and kms_key_id are set for ${var.name}; the created key is used and kms_key_id is ignored."
  }
}

check "high_availability" {
  assert {
    condition     = length(local.instances) < 2 || length(distinct([for subnet in data.aws_subnet.selected : subnet.availability_zone])) >= var.minimum_availability_zones
    error_message = "The subnets for ${var.name} span fewer than ${var.minimum_availability_zones} availability zones, which limits where Aurora can place its instances and their replacements."
  }

  assert {
    condition     = alltrue([for group in var.instance_groups : group.count >= 2 if group.custom_endpoint])
    error_message = "An instance group in ${var.name} exposes a custom endpoint but holds one instance, so the endpoint serves no connections whenever that instance is the writer or is unavailable."
  }
}
