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

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      }

    ],
  })
}


resource "aws_iam_policy" "ecs_task_ssm_policy" {
  name = "ecs_task_ssm_policy"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeSessions",
          "ecs:ExecuteCommand"
        ],
        "Resource": "*"
      }
    ]
  }
EOF
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

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_ssm_policy.arn
}


resource "aws_secretsmanager_secret" "postgres_cube_user_pw" {
  name = "production/postgres-cube-user-pw"
}

resource "aws_secretsmanager_secret" "auth0_jwt_key" {
  name = "production/auth0-jwt-key"
}

variable "cubestore_worker_count" {
  default = 2
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
      name  = "CUBEJS_DB_HOST"
      value = "ec2-3-221-59-105.compute-1.amazonaws.com"
    },
    {
      name  = "CUBEJS_DB_PORT"
      value = "5432"
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
      value = "false"
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
  cubestore_task_dns_names = join(",", [for i in range(var.cubestore_worker_count) : "cubestore-worker-${i}:80"])

  cube_api_container_definitions = jsonencode([
    {
      name      = "cube-api"
      image     = "${aws_ecr_repository.sync_svc_cube_repo.repository_url}:latest"
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
          name          = "cube-api-port"
        },
      ],
      environment = concat(local.cube_shared_environment,
        [
          {
            name  = "CUBEJS_REFRESH_WORKER"
            value = "false"
          },
          {
            name  = "PORT"
            value = "80"
          },
          {
            name  = "CUBEJS_CUBESTORE_HOST"
            value = "cubestore-router-http"
          },
          {
            name  = "CUBEJS_CUBESTORE_PORT"
            value = "3030"
          }
        ]
      ),
      secrets = local.cube_shared_secrets
    }
  ])

  cube_refresh_worker_container_definitions = jsonencode([
    {
      name      = "cube-refresh-worker"
      image     = "${aws_ecr_repository.sync_svc_cube_repo.repository_url}:latest"
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
          name          = "cube-refresh-worker-port"
        },
      ],
      environment = concat(local.cube_shared_environment,
        [{
          name  = "CUBEJS_REFRESH_WORKER"
          value = "true"
          },
          {
            name  = "CUBEJS_CUBESTORE_HOST"
            value = "cubestore-router-http"
          },
          {
            name  = "CUBEJS_CUBESTORE_PORT"
            value = "3030"
        }]
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
          name          = "cubestore-router-port"
        },
        {
          containerPort = 3030,
          hostPort      = 3030,
          protocol      = "tcp",
          name          = "cubestore-router-http-port"
        },
        {
          containerPort = 3031,
          hostPort      = 3031,
          protocol      = "tcp",
          name          = "cubestore-router-status-port"
        }
      ],
      environment = concat(local.cube_shared_environment,
        [{
          name  = "CUBESTORE_SERVER_NAME"
          value = "cubestore-router:80"
          },
          {
            name  = "CUBESTORE_META_PORT"
            value = "80"
          },
          {
            name  = "CUBESTORE_WORKERS"
            value = "${local.cubestore_task_dns_names}"
          },
          {
            name  = "CUBESTORE_REMOTE_DIR"
            value = "/cube/data"
        }]
      ),
      secrets = local.cube_shared_secrets
    },
  ])
}

resource "aws_ecs_task_definition" "cube_api" {
  family                   = "cube_api"
  container_definitions    = local.cube_api_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cube_api" {
  name                   = "cube_api"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cube_api.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cubestore.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "cube-api"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "cube_refresh_worker" {
  family                   = "cube_refresh_worker"
  container_definitions    = local.cube_refresh_worker_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cube_refresh_worker" {
  name                   = "cube_refresh_worker"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cube_refresh_worker.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cubestore.arn
  }
}

resource "aws_service_discovery_http_namespace" "cubestore" {
  name        = "cubestore.local"
  description = "Service discovery namespace for cubestore workers and router"
}

resource "aws_ecs_service" "cubestore_router" {
  name                   = "cubestore_router"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cubestore_router.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cubestore.arn
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name,
        "awslogs-region"        = "us-east-1",
        "awslogs-stream-prefix" = "ecs"
      }
    }
    service {
      discovery_name = "cubestore-router"
      port_name      = "cubestore-router-port"
      client_alias {
        port     = 80
        dns_name = "cubestore-router"
      }
    }

    service {
      discovery_name = "cubestore-router-status"
      port_name      = "cubestore-router-status-port"
      client_alias {
        port     = 3031
        dns_name = "cubestore-router-status"
      }
    }

    service {
      discovery_name = "cubestore-router-http"
      port_name      = "cubestore-router-http-port"
      client_alias {
        port     = 3030
        dns_name = "cubestore-router-http"
      }
    }
  }
}

resource "aws_ecs_task_definition" "cubestore_router" {
  family                   = "cubestore_router"
  container_definitions    = local.cubestore_router_container_definitions
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "cubestore" {
  count = var.cubestore_worker_count

  name                   = "cubestore_${count.index}"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cubestore[count.index].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0


  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cubestore.arn
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name,
        "awslogs-region"        = "us-east-1",
        "awslogs-stream-prefix" = "ecs"
      }
    }
    service {
      discovery_name = "cubestore-worker-${count.index}"
      port_name      = "cubestore-worker-port"
      client_alias {
        port     = 80
        dns_name = "cubestore-worker-${count.index}"
      }
    }
  }

  # service_registries {
  #   registry_arn = aws_service_discovery_service.cubestore[count.index].arn
  # }
}

resource "aws_ecs_task_definition" "cubestore" {
  count = var.cubestore_worker_count

  family                   = "cubestore-${count.index}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
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
          name          = "cubestore-worker-port"
        }
      ],
      environment = concat(local.cube_shared_environment,
        [{
          name  = "CUBESTORE_SERVER_NAME"
          value = "cubestore-worker-${count.index}:80"
          },
          {
            name  = "CUBESTORE_WORKER_PORT"
            value = "80"
          },
          {
            name  = "CUBESTORE_META_ADDR"
            value = "cubestore-router:80"
          },
          {
            name  = "CUBESTORE_WORKERS"
            value = "${local.cubestore_task_dns_names}"
          },
          {
            name  = "CUBESTORE_REMOTE_DIR"
            value = "/cube/data"
        }]
      ),
      secrets = local.cube_shared_secrets
    }
  ])

}
