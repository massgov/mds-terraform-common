// S3
resource "aws_s3_bucket" "mds_static_site" {
  // bucket's name = domain name
  bucket = "${var.sub_domain_name}"
  // We also need to create a policy that allows anyone to view the content.
  // This is basically duplicating what we did in the ACL but it's required by
  // AWS. This post: http://amzn.to/2Fa04ul explains why.
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.sub_domain_name}/*"]
    }
  ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# top level domain
data "aws_route53_zone" "tld" {
  name = "${var.root_domain_name}"
}

// TLS/SSL certificate
resource "aws_acm_certificate" "default" {
  // wildcard cert if we want to host sub-subdomains later.
  domain_name       = "*.${var.sub_domain_name}"
  validation_method = "DNS"
}

# dns record to use for certificate validation
resource "aws_route53_record" "default" {
  name    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.tld.zone_id}"
  records = ["${aws_acm_certificate.default.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

# validate the certificate with the dns entry
resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = ["${aws_route53_record.default.fqdn}"]
}

// Cloudfront
resource "aws_cloudfront_distribution" "sub_domain_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    // S3 bucker url
    domain_name = "${aws_s3_bucket.mds_static_site.website_endpoint}"
    origin_id   = "${var.sub_domain_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.sub_domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = true
      headers      = ["Host"]
      cookies {
        forward = "none"
      }
    }
  }

  // hit Cloudfront distribution using sub domain url
  aliases = ["${var.sub_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
      // list of countries e.g. ["US", "CA", "GB", "DE"]
      locations        = []
    }
  }

  // serve with cert
  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.default.arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method  = "sni-only"
  }

  tags = "${var.tags}"

}


// root/zone
resource "aws_route53_zone" "zone" {
  name = "${var.root_domain_name}"
}


// point Route53 record will point at our CloudFront distribution.
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${var.sub_domain_name}"
  type    = "CNAME"

  alias = {
    name                   = "${aws_cloudfront_distribution.sub_domain_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.sub_domain_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_identity" "edge" {
    comment = "Cloudfront ID for ${aws_s3_bucket.mds_static_site.bucket}"
}
