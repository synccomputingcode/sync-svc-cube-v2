resource "aws_ssm_parameter" "sync_svc_cube_cdn_distribution_id" {
  name  = "/sync-svc-cube/cdn/distribution_id"
  type  = "String"
  value = aws_cloudfront_distribution.sync_svc_cube_cdn.id
}
