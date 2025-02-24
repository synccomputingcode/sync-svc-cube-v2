data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_origin_request_policy" "all_viewers" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "sync_svc_cube_cdn" {
  aliases         = [local.domain_name, "www.${local.domain_name}"]
  comment         = "Cloudfront distribution for cube.dev api"
  price_class     = "PriceClass_100"
  is_ipv6_enabled = true
  enabled         = true

  origin {
    domain_name = local.api_domain_name
    origin_id   = local.api_domain_name

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.alb.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }

    # custom_origin_config {
    #   http_port                = 80
    #   https_port               = 443
    #   origin_keepalive_timeout = 5
    #   origin_protocol_policy   = "match-viewer"
    #   origin_read_timeout      = 30
    #   origin_ssl_protocols     = ["TLSv1.2"]
    # }
  }

  default_cache_behavior {
    target_origin_id         = local.api_domain_name
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewers.id
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}
