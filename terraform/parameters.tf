resource "aws_ssm_parameter" "resume_cdn_distribution_id" {
  name  = "/resume/cdn/distribution_id"
  type  = "String"
  value = module.resume_cdn.cloudfront_distribution_id
}

resource "aws_ssm_parameter" "resume_s3_bucket" {
  name  = "/resume/s3/bucket"
  type  = "String"
  value = module.resume_s3_bucket.s3_bucket_id
}
