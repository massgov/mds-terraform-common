output "restriction_type" {
  value = var.enabled ? "blacklist" : "none"
}

output "locations" {
  value = var.enabled ? (
    var.create_country_code_list
    ? split(",", nonsensitive(aws_ssm_parameter.country_codes[0].value))
    : local.locations
  ) : []
}
