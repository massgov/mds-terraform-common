locals {
  primary_domain_name    = var.domain_names[0]
  secondary_domain_names = slice(var.domain_names, 1, length(var.domain_names))
}

resource "aws_acm_certificate" "default" {
  domain_name               = local.primary_domain_name
  validation_method         = "DNS"
  subject_alternative_names = local.secondary_domain_names

  tags = merge(var.tags, {
    "Name" = var.name
  })

  // Replace certificate that is currently in use.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "verification" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.verification : record.fqdn]
}
