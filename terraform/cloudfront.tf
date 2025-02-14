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



module "sync_svc_cube_cdn" {
  source          = "terraform-aws-modules/cloudfront/aws"
  version         = "3.4.0"
  aliases         = [local.domain_name, "www.${local.domain_name}"]
  is_ipv6_enabled = true
  comment         = "Cloudfront distribution for cube.dev api"
  price_class     = "PriceClass_100"

  origin = {
    domain_name = local.api_domain_name
    origin_id   = local.api_domain_name
    custom_origin_config = {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "match-viewer"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  default_cache_behavior = {
    target_origin_id         = local.api_domain_name
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewers.id
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    use_forwarded_values     = false
  }

  viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}
