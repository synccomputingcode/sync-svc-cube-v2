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



module "sync-svc-cube_cdn" {
  source              = "terraform-aws-modules/cloudfront/aws"
  version             = "3.4.0"
  aliases             = [local.domain_name, "www.${local.domain_name}"]
  is_ipv6_enabled     = true
  comment             = "Cloudfront distribution for coiled static assets."
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    elb = {
      domain_name = local.api_domain_name
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
    s3 = {
      domain_name           = module.resume_s3_bucket.s3_bucket_bucket_domain_name
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3origin.id
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    compress                 = true
    use_forwarded_values     = false
  }


  ordered_cache_behavior = [
    {
      path_pattern             = "/api/*"
      target_origin_id         = "elb"
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewers.id
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = true
      use_forwarded_values     = false
    },
    {
      path_pattern             = "/admin/*"
      target_origin_id         = "elb"
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewers.id
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = true
      use_forwarded_values     = false
    }
  ]
  custom_error_response = [
    {
      response_page_path = "/index.html"
      error_code         = 404
      response_code      = 200
    }
  ]

  viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}
