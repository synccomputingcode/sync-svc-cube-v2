
locals {
  domain_name     = var.cube_api_domain_name
  api_domain_name = "internal-${var.cluster_prefix}-cube-api-lb.${local.domain_name}"
}

resource "aws_route53_zone" "main" {
  name = local.domain_name
}

resource "aws_acm_certificate" "main" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "lb" {
  domain_name       = local.api_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_route53_record" "lb_cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.lb.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]
}

resource "aws_acm_certificate_validation" "lb" {
  certificate_arn         = aws_acm_certificate.lb.arn
  validation_record_fqdns = [for record in aws_route53_record.lb_cert_validation_records : record.fqdn]
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cube_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cube_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "lb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.api_domain_name
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
