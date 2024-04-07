module "resume_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "shughes-resume-frontend-bucket"
  force_destroy = true
}

data "aws_iam_policy_document" "s3_policy" {

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.resume_s3_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.resume_cdn.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.resume_s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}
