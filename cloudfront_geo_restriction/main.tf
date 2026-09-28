data "aws_ssm_parameter" "country_codes" {
  name = "/infrastructure/geo-blocking/country-codes"
}

locals {
  locations = data.aws_ssm_parameter.country_codes.value == "" ? [] : split(",", nonsensitive(data.aws_ssm_parameter.country_codes.value))
}

resource "aws_ssm_parameter" "country_codes" {
  count     = var.create_country_code_list && var.enabled ? 1 : 0
  name      = "/infrastructure/geo-blocking/country-codes"
  type      = "String"
  value     = var.country_codes
  overwrite = var.overwrite_country_code_params
}
