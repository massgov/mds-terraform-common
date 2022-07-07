output "restriction_type" {
  value = var.enabled ? "blacklist" : "none"
}

output "locations" {
  value = var.enabled ? local.locations : []
}
