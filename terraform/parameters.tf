resource "aws_ssm_parameter" "resume_cdn_distribution_id" {
  name  = "/resume/cdn/distribution_id"
  type  = "String"
  value = module.resume_cdn.cloudfront_distribution_id
}
