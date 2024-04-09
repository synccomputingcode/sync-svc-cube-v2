
module "resume_cdn" {
  source              = "terraform-aws-modules/cloudfront/aws"
  version             = "3.4.0"
  is_ipv6_enabled     = true
  comment             = "Cloudfront distribution for coiled static assets."
  default_root_object = "/index.html"
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
    s3 = {
      domain_name           = module.resume_s3_bucket.s3_bucket_bucket_domain_name
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    use_forwarded_values = false

    # aws managed cache policy CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # aws managed headers policy SecurityHeadersPolicy
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }

  custom_error_response = [{
    response_code      = 200
    response_page_path = "index.html"
    error_code         = 404
  }]

  #   viewer_certificate = {
  #     cloudfront_default_certificate = false
  #     acm_certificate_arn            = aws_acm_certificate.main_cloudfront.arn
  #     ssl_support_method             = "sni-only"
  #     minimum_protocol_version       = "TLSv1.2_2021"
  #   }
}
