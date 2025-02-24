resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/sync-svc-cube/production"
  retention_in_days = 14
}
