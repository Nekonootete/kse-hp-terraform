provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_acm_certificate" "cert" {
  provider = aws.virginia
  domain   = var.domain_name
  types    = ["AMAZON_ISSUED"]
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_origin_request_policy" "all_viewer" {
  name    = "origin-request-all-viewer-${var.project_name}-${var.environment}"
  comment = "Forward all headers, cookies and query strings to ALB"

  headers_config {
    header_behavior = "allViewer"
  }

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_origin_request_policy" "no_forward" {
  name = "no-forward-${var.project_name}-${var.environment}"
  comment = "Forward no headers to ALB"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_cache_policy" "caching_disabled" {
  name        = "caching-disabled-${var.project_name}-${var.environment}"
  comment     = "Disable cache for dynamic ALB origin"
  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config  { header_behavior  = "none" }
    cookies_config  { cookie_behavior  = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CDN in front of ALB (Next.js / Rails)"
  aliases         = [var.fqdn, var.cdn_fqdn]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-${var.project_name}-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/_next/static/*"
    target_origin_id         = "alb-${var.project_name}-${var.environment}"
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    origin_request_policy_id = aws_cloudfront_origin_request_policy.no_forward.id
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress                 = true
  }

  ordered_cache_behavior {
  path_pattern             = "/rails/active_storage/*"
  target_origin_id         = "alb-${var.project_name}-${var.environment}"
  viewer_protocol_policy   = "https-only"
  allowed_methods          = ["GET", "HEAD"]
  cached_methods           = ["GET", "HEAD"]
  origin_request_policy_id = aws_cloudfront_origin_request_policy.no_forward.id
  cache_policy_id          = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d"
  compress                 = true
}

  default_cache_behavior {
    target_origin_id         = "alb-${var.project_name}-${var.environment}"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    origin_request_policy_id = aws_cloudfront_origin_request_policy.all_viewer.id
    cache_policy_id          = aws_cloudfront_cache_policy.caching_disabled.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "cdn-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}