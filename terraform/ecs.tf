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
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.postgres_cube_user_pw.arn,
      aws_secretsmanager_secret.auth0_jwt_key.arn
    ]
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
}

resource "aws_iam_policy" "ecs_task_execution_role_policy" {
  name        = "ecs_task_execution_role_policy"
  description = "Policy for ECS Task Execution Role to get secrets"
  policy      = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_managed" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_secretsmanager_secret" "postgres_cube_user_pw" {
  name = "production-postgres-cube-user-pw"
}

resource "aws_secretsmanager_secret_version" "postgres_cube_user_pw" {
  secret_id = aws_secretsmanager_secret.postgres_cube_user_pw.id

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "auth0_jwt_key" {
  name = "production-auth0-jwt-key"
}

resource "aws_secretsmanager_secret_version" "auth0_jwt_key" {
  secret_id = aws_secretsmanager_secret.auth0_jwt_key.id

  lifecycle {
    ignore_changes = [secret_string]
  }
}



locals {
  cube_shared_environment = [
    {
      name  = "CUBEJS_DB_SSL"
      value = "true"
    },
    {
      name  = "CUBEJS_DB_TYPE"
      value = "postgres"
    },
    {
      name  = "CUBEJS_DB_TYPE"
      value = "postgres"
    },
    {
      name  = "CUBEJS_DB_TYPE"
      value = "postgres"
    },
    {
      name  = "CUBEJS_DB_USER"
      value = "cube"
    },
    {
      name  = "CUBEJS_DB_NAME"
      value = "d20nhfliefb6aa"
    },
    {
      name  = "CUBEJS_SCHEMA_PATH"
      value = "model"
    },
    {
      name  = "CUBEJS_DEV_MODE"
      value = "true"
    },
    {
      name  = "NODE_ENV",
      value = "production"
    },
    {
      name  = "CUBEJS_JWK_URL"
      value = "https://sync-prod.us.auth0.com/.well-known/jwks.json"
    },
    {
      name  = "CUBEJS_JWT_AUDIENCE"
      value = "https://api.synccomputing.com"
    },
    {
      name  = "CUBEJS_JWT_ISSUER"
      value = "https://login.app.synccomputing.com/"
    },
    {
      name  = "CUBEJS_JWT_ALGS"
      value = "RS256"
    },
    {
      name  = "CUBEJS_JWT_CLAIMS_NAMESPACE"
      value = "https://synccomputing.com/"
    }
  ]
  cube_shared_secrets = [
    { name = "CUBEJS_DB_PASS", valueFrom = aws_secretsmanager_secret.postgres_cube_user_pw.arn },
    { name = "CUBEJS_JWT_KEY", valueFrom = aws_secretsmanager_secret.auth0_jwt_key.arn },
  ]
  cube_api_container_definitions = jsonencode([
    {
      name      = "cube-api"
      image     = "${var.cube_image}"
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
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
        },
      ],
      environment = concat(local.cube_shared_environment,
        {
          name  = "CUBEJS_REFRESH_WORKER"
          value = "false"
        },
      ),
      secrets = local.cube_shared_secrets
    }
  ])

  cube_refresh_worker_container_definitions = jsonencode([
    {
      name      = "cube-refresh-worker"
      image     = "${var.cube_image}"
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
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
        },
      ],
      environment = concat(local.cube_shared_environment,
        {
          name  = "CUBEJS_REFRESH_WORKER"
          value = "true"
        },
      ),
      secrets = local.cube_shared_secrets
    }
  ])

  cubestore_router_container_definitions = jsonencode([
    {
      name      = "cubestore-router"
      image     = "${var.cubestore_image}"
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
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
        },
      ],
      environment = concat(local.cube_shared_environment,
        {
          name  = "CUBESTORE_SERVER_NAME"
          value = "${aws_lb.cubestore_router.dns_name}:${aws_lb.cubestore_router.port}"
        },
        {
          name  = "CUBESTORE_META_PORT"
          value = "${aws_lb.cubestore_router.port}"
        },
        {
          name  = "CUBESTORE_WORKERS"
          value = "${aws_lb.cubestore.dns_name}:${aws_lb.cubestore.port}"
        },
        {
          name  = "CUBESTORE_REMOTE_DIR"
          value = "/cube/data"
        },
      ),
      secrets = local.cube_shared_secrets
    },
  ])

  cubestore_container_definitions = jsonencode([
    {
      name      = "cubestore"
      image     = "${var.cubestore_image}"
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
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
        },
      ],
      environment = concat(local.cube_shared_environment,
        {
          name  = "CUBESTORE_WORKER_PORT"
          value = "80"
        },
        {
          name  = "CUBESTORE_META_ADDR"
          value = "${aws_lb.cubestore_router.dns_name}:${aws_lb.cubestore_router.port}"
        },
        {
          name  = "CUBESTORE_WORKERS"
          value = "${aws_lb.cubestore.dns_name}:${aws_lb.cubestore.port}"
        },
        {
          name  = "CUBESTORE_REMOTE_DIR"
          value = "/cube/data"
        },
      ),
      secrets = local.cube_shared_secrets
    }
  ])
}

resource "aws_ecs_task_definition" "cube_api" {
  family                   = "production"
  container_definitions    = local.cube_api_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cube_api" {
  name                  = "production"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.cube_api.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "cube-api"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "cube_refresh_worker" {
  family                   = "production"
  container_definitions    = local.cube_refresh_worker_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cube_refresh_worker" {
  name                  = "production"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.cube_refresh_worker.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0
}

resource "aws_ecs_service" "cubestore_router" {
  name                  = "production"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.cubestore_router.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cubestore_router.arn
    container_name   = "cubestore_router"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "cubestore_router" {
  family                   = "production"
  container_definitions    = local.cubestore_router_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cubestore" {
  name                  = "production"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.cubestore.arn
  desired_count         = 2
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cubestore.arn
    container_name   = "cubestore"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "cubestore" {
  family                   = "production"
  container_definitions    = local.cubestore_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

