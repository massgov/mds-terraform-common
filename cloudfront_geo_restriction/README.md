CloudFront Geo-Restriction
=================

This Terraform module outputs geo-restriction that is applicable to CloudFront distributions.

By default, the module reads the comma-separated country-code list from the
`/infrastructure/geo-blocking/country-codes` SSM parameter. Set
`create_country_code_list` to `true` to create the parameter, or overwrite an
existing parameter when `overwrite_country_code_params` is also `true`, using
the value of `country_codes`.

When `enabled` is `false`, the module returns `restriction_type = "none"` and an
empty `locations` list and does not create the SSM parameter.

Example
-------

```hcl
module "cloudfront_geo_restriction" {
  source = "github.com/massgov/mds-terraform-common//cloudfront_geo_restriction?ref=<version>"

  enabled                       = true
  create_country_code_list      = true
  overwrite_country_code_params = true
  country_codes                 = "AE,AF,CN,CU,IR,KP,RU"
}

resource "aws_cloudfront_distribution" "example" {
  # Other distribution configuration omitted.

  restrictions {
    geo_restriction {
      restriction_type = module.cloudfront_geo_restriction.restriction_type
      locations         = module.cloudfront_geo_restriction.locations
    }
  }
}
```
