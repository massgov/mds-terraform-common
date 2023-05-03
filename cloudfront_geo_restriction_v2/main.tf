module "cf_geo_restriction" {
  source  = "github.com/massgov/mds-terraform-common//cloudfront_geo_restriction?ref=1.0.51"
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

  rule {
    name     = "${var.name_prefix}-restrict-contries"
    priority = 1

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
        country_codes = module.cf_geo_restriction.locations
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
      metric_name                = "${var.name_prefix}-restrict-contries-metrics"
      sampled_requests_enabled   = false
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
    metric_name                = "${var.name_prefix}-web-acl-metrics"
    sampled_requests_enabled   = false
  }
}
