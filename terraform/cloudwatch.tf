resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/resume-backend/production"
  retention_in_days = 14
}
