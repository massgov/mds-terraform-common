locals {
  primary_domain_name = var.domain_names[0]
  secondary_domain_names = slice(var.domain_names, 1, length(var.domain_names))
}

resource "aws_acm_certificate" "default" {
  domain_name = local.primary_domain_name
  validation_method = "DNS"
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
  count = length(var.domain_names)
  name = aws_acm_certificate.default.domain_validation_options[count.index].resource_record_name
  type = aws_acm_certificate.default.domain_validation_options[count.index].resource_record_type
  records = [aws_acm_certificate.default.domain_validation_options[count.index].resource_record_value]
  zone_id = var.zone_id
  ttl = "60"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = aws_acm_certificate.default.arn
  validation_record_fqdns = aws_route53_record.verification.*.fqdn
}
