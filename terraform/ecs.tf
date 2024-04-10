resource "aws_ecs_cluster" "main" {
  name = "production"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.main.master_user_secret.0.secret_arn]
  }
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
  inline_policy {
    name   = "ecs_task_execution_role_get_secret"
    policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

locals {
  container_definitions = jsonencode([
    {
      name      = "backend-api"
      image     = "${var.app_image}"
      cpu       = 256
      memory    = 512
      essential = true
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = 8000,
          protocol      = "tcp",
        },
      ],
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.endpoint
        },
        {
          name  = "DB_PORT"
          value = tostring(aws_db_instance.main.port)
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.main.db_name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.main.username
        },
      ],
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.main.master_user_secret.0.secret_arn}:password::"
        },
      ]
    },
  ])
}

resource "aws_ecs_task_definition" "main" {
  family                   = "production"
  container_definitions    = local.container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "main" {
  name                  = "production"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.main.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "backend-api"
    container_port   = 8000
  }
}
