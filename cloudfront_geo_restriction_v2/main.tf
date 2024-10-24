module "cf_geo_restriction" {
  source  = "../cloudfront_geo_restriction"
  enabled = true
}

resource "aws_wafv2_web_acl" "default" {
  name        = "${var.name_prefix}-web-acl"
  description = "Web ACL that rejects requests to Cloudfront from blocked countries"
  scope       = "CLOUDFRONT"

  custom_response_body {
    key          = "custom-response-forbidden"
    content      = "Forbidden"
    content_type = "TEXT_PLAIN"
  }

  default_action {
    allow {}
  }

  dynamic "rule" {
    // wafv2 doesn't support country code lists larger than 50 codes
    for_each = { for i, chunk in chunklist(module.cf_geo_restriction.locations, 50) : i => chunk }
    content {
      name     = "${var.name_prefix}-restrict-countries-rule-${rule.key}"
      priority = tonumber(rule.key)

      action {
        block {
          custom_response {
            response_code            = 403
            custom_response_body_key = "custom-response-forbidden"
          }
        }
      }

      statement {
        geo_match_statement {
          country_codes = rule.value
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${var.name_prefix}-restrict-countries-rule-${rule.key}"
        sampled_requests_enabled   = false
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-web-acl"
    }
  )

  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    metric_name                = "${var.name_prefix}-web-acl"
    sampled_requests_enabled   = false
  }
}
