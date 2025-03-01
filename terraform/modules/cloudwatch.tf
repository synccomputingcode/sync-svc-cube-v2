resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.cluster_prefix}-cube-logs"
  retention_in_days = 14
}
