// S3 bucket for static site
resource "aws_s3_bucket" "mds_static_site" {
  // bucket's name = domain name
  bucket = "${var.sub_domain_name}"
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
    // bucket root; subfolders are handled by a lambda@edge
    index_document = "index.html"
    error_document = "404.html"
  }
}


// top level domain where subdomains are added
data "aws_route53_zone" "tld" {
  name = "${var.root_domain_name}"
}

// TLS/SSL certificate for the subdomain
resource "aws_acm_certificate" "default" {
  // wildcard cert if we want to host sub-subdomains later.
  domain_name       = "*.${var.sub_domain_name}"
  // rely on a DNS entry for validating the certificate
  validation_method = "DNS"
}


// dns record to use for certificate validation
// create the DNS entry in the root and relevant zone
resource "aws_route53_record" "default" {
  name    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.tld.zone_id}"
  records = ["${aws_acm_certificate.default.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}


// validate the certificate with a dns entry
resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = ["${aws_route53_record.default.fqdn}"]
}


// get "AlwaysRequestIndexHTML" lambda and store its metadata
data "aws_lambda_function" "index_html" {
  function_name = "${var.always_get_index_html_lambda}"
}


// get the "s3_edge_header" lambda and store its metadata
data "aws_lambda_function" "s3_headers" {
  function_name = "${var.s3_edge_header_lambda}"
}


// Cloudfront
// cdn the subdomain
resource "aws_cloudfront_distribution" "sub_domain_distribution" {
  origin {
    // S3 bucker url
    domain_name = "${aws_s3_bucket.mds_static_site.website_endpoint}"

    // identifies the origin with a name (can be any string of choice)
    origin_id   = "${var.sub_domain_name}"

    // since the s3 bucker is not directly accessed by the public
    // identity to access the cloudfront distro
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.edge.cloudfront_access_identity_path}"
    }
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
    default_ttl            = 3600
    max_ttl                = 86400

    // associate the "AlwaysRequestIndexHTML" lambda with CF
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = "${data.aws_lambda_function.index_html.arn}"
    }

    // associate the "s3_edge_header" lambda with CF
    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${data.aws_lambda_function.s3_headers.arn}"
    }

    forwarded_values {
      query_string = true
      headers      = ["Host"]
      cookies {
        forward = "none"
      }
    }
  }

  // hit Cloudfront using the sub domain url
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

// create an identity to access origin
resource "aws_cloudfront_origin_access_identity" "edge" {
    comment = "Cloudfront ID for ${aws_s3_bucket.mds_static_site.bucket}"
}
