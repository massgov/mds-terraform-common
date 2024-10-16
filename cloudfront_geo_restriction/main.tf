data "aws_ssm_parameter" "country_codes" {
  name = "/infrastructure/geo-blocking/country-codes"
}

locals {
  locations = data.aws_ssm_parameter.country_codes.value == "" ? [] : split(",", nonsensitive(data.aws_ssm_parameter.country_codes.value))
}
