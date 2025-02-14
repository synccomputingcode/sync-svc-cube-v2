resource "aws_ssm_parameter" "sync_svc_cube_cdn_distribution_id" {
  name  = "/sync-svc-cube/cdn/distribution_id"
  type  = "String"
  value = module.sync_svc_cube_cdn.cloudfront_distribution_id
}
