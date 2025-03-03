resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_prefix}_cluster"

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

data "aws_secretsmanager_secret" "secrets" {
  for_each = toset(var.cube_shared_secrets)
  name     = each.valueFrom
}

locals {
  secret_arns = [for s in data.aws_secretsmanager_secret.secrets : s.arn]
}


data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = local.secret_arns
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_prefix}_ecs_task_execution_role"

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
  name = "${var.cluster_prefix}_ecs_task_role"

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
  name = "${var.cluster_prefix}_ecs_task_ssm_policy"

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

locals {
  cubestore_worker_port       = 80
  cubestore_worker_port_name  = "cubestore-worker-port"
  cubestore_worker_dns_prefix = "cubestore-worker"
  cubestore_task_dns_names    = join(",", [for i in range(var.cubestore_worker_resources.cubestore_worker_count) : "${local.cubestore_worker_dns_prefix}-${i}:${local.cubestore_worker_port}"])

  cubestore_router_dns_name  = "cubestore-router"
  cubestore_router_port      = 80
  cubestore_router_port_name = "cubestore-router-port"

  cubestore_router_http_dns_name  = "cubestore-router-http"
  cubestore_router_http_port_name = "cubestore-router-http-port"
  cubestore_router_http_port      = 3030

  cubestore_router_status_dns_name  = "cubestore-router-status"
  cubestore_router_status_port_name = "cubestore-router-status-port"
  cubestore_router_status_port      = 3031

  cube_api_port = 80
}

resource "aws_ecs_task_definition" "cube_api" {
  family = "cube_api"
  container_definitions = jsonencode([
    {
      name      = "cube-api"
      image     = "${aws_ecr_repository.sync_svc_cube_repo.repository_url}:latest"
      cpu       = var.cube_api_resources.cpu
      memory    = var.cube_api_resources.memory
      essential = true
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.cube_api_port}/readyz || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 60 # Grace period before starting checks (in seconds)
        timeout     = 5
      }
      portMappings = [
        {
          containerPort = local.cube_api_port,
          hostPort      = local.cube_api_port,
          protocol      = "tcp",
          name          = "cube-api-port"
        },
      ],
      environment = concat(var.cube_shared_env,
        [
          {
            name  = "CUBEJS_REFRESH_WORKER"
            value = "false"
          },
          {
            name  = "PORT"
            value = local.cube_api_port
          },
          {
            name  = "CUBEJS_CUBESTORE_HOST"
            value = local.cubestore_router_http_dns_name
          },
          {
            name  = "CUBEJS_CUBESTORE_PORT"
            value = local.cubestore_router_http_port
          }
        ]
      ),
      secrets = var.cube_shared_secrets
    }
  ])
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cube_api_resources.cpu
  memory                   = var.cube_api_resources.memory
}

resource "aws_ecs_service" "cube_api" {
  name                   = "cube_api"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cube_api.arn
  desired_count          = var.cube_api_resources.desired_worker_count
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = data.aws_vpc.selected.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cube.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "cube-api"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "cube_refresh_worker" {
  family = "cube_refresh_worker"
  container_definitions = jsonencode([
    {
      name      = "cube-refresh-worker"
      image     = "${aws_ecr_repository.sync_svc_cube_repo.repository_url}:latest"
      cpu       = var.cube_refresh_worker_resources.cpu
      memory    = var.cube_refresh_worker_resources.memory
      essential = true
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:80/readyz || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 60 # Grace period before starting checks (in seconds)
        timeout     = 5
      }
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
          name          = "cube-refresh-worker-port"
        },
      ],
      environment = concat(var.cube_shared_env,
        [{
          name  = "CUBEJS_REFRESH_WORKER"
          value = "true"
          },
          {
            name  = "CUBEJS_CUBESTORE_HOST"
            value = local.cubestore_router_http_dns_name
          },
          {
            name  = "CUBEJS_CUBESTORE_PORT"
            value = local.cubestore_router_http_port
        }]
      ),
      secrets = var.cube_shared_secrets
    }
  ])
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cube_refresh_worker_resources.cpu
  memory                   = var.cube_refresh_worker_resources.memory
}

resource "aws_ecs_service" "cube_refresh_worker" {
  name                   = "cube_refresh_worker"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cube_refresh_worker.arn
  desired_count          = var.cube_refresh_worker_resources.desired_worker_count
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets         = data.aws_vpc.selected.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cube.arn
  }
}

resource "aws_service_discovery_http_namespace" "cube" {
  name        = "${var.cluster_prefix}-cube.local"
  description = "Service discovery namespace to form a cube cluster"
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
    subnets         = data.aws_vpc.selected.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cube.arn
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name,
        "awslogs-region"        = "us-east-1",
        "awslogs-stream-prefix" = "ecs"
      }
    }
    service {
      discovery_name = local.cubestore_router_dns_name
      port_name      = local.cubestore_router_port_name
      client_alias {
        port     = local.cubestore_router_port
        dns_name = local.cubestore_router_dns_name
      }
    }

    service {
      discovery_name = local.cubestore_router_status_dns_name
      port_name      = local.cubestore_router_status_port_name
      client_alias {
        port     = local.cubestore_router_status_port
        dns_name = local.cubestore_router_status_dns_name
      }
    }

    service {
      discovery_name = local.cubestore_router_http_dns_name
      port_name      = local.cubestore_router_http_port_name
      client_alias {
        port     = local.cubestore_router_http_port
        dns_name = local.cubestore_router_http_dns_name
      }
    }
  }
}

resource "aws_ecs_task_definition" "cubestore_router" {
  family = "cubestore_router"
  container_definitions = jsonencode([
    {
      name      = "cubestore-router"
      image     = "${var.cubestore_image}"
      cpu       = var.cubestore_router_resources.cpu
      memory    = var.cubestore_router_resources.memory
      essential = true
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.cubestore_router_status_port}/readyz || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 60 # Grace period before starting checks (in seconds)
        timeout     = 5
      }
      portMappings = [
        {
          containerPort = local.cubestore_router_port,
          hostPort      = local.cubestore_router_port,
          protocol      = "tcp",
          name          = local.cubestore_router_port_name
        },
        {
          containerPort = local.cubestore_router_http_port,
          hostPort      = local.cubestore_router_http_port,
          protocol      = "tcp",
          name          = local.cubestore_router_http_port_name
        },
        {
          containerPort = local.cubestore_router_status_port,
          hostPort      = local.cubestore_router_status_port,
          protocol      = "tcp",
          name          = local.cubestore_router_status_port_name
        }
      ],
      environment = [{
        name  = "CUBESTORE_SERVER_NAME"
        value = "${local.cubestore_router_dns_name}:${local.cubestore_router_port}"
        },
        {
          name  = "CUBESTORE_META_PORT"
          value = local.cubestore_router_port
        },
        {
          name  = "CUBESTORE_WORKERS"
          value = "${local.cubestore_task_dns_names}"
        },
        {
          name  = "CUBESTORE_REMOTE_DIR"
          value = "/cube/data"
      }]
    },
  ])
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cubestore_router_resources.cpu
  memory                   = var.cubestore_router_resources.memory
}

resource "aws_ecs_service" "cubestore" {
  count = var.cubestore_worker_resources.cubestore_worker_count

  name                   = "cubestore_${count.index}"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.cubestore[count.index].arn
  desired_count          = var.cubestore_worker_resources.cubestore_worker_count
  launch_type            = "FARGATE"
  wait_for_steady_state  = true
  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0


  network_configuration {
    subnets          = data.aws_vpc.selected.private_subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cube.arn
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name,
        "awslogs-region"        = "us-east-1",
        "awslogs-stream-prefix" = "ecs"
      }
    }
    service {
      discovery_name = "${local.cubestore_worker_dns_prefix}-${count.index}"
      port_name      = local.cubestore_worker_port_name
      client_alias {
        port     = local.cubestore_worker_port
        dns_name = "${local.cubestore_worker_dns_prefix}-${count.index}"
      }
    }
  }
}

resource "aws_ecs_task_definition" "cubestore" {
  count = var.cubestore_worker_resources.cubestore_worker_count

  family                   = "cubestore-${count.index}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cubestore_worker_resources.cpu
  memory                   = var.cubestore_worker_resources.memory

  container_definitions = jsonencode([
    {
      name      = "cubestore"
      image     = "${var.cubestore_image}"
      cpu       = var.cubestore_worker_resources.cpu
      memory    = var.cubestore_worker_resources.memory
      essential = true
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3031/readyz || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 60 # Grace period before starting checks (in seconds)
        timeout     = 5
      }
      portMappings = [
        {
          containerPort = local.cubestore_worker_port,
          hostPort      = local.cubestore_worker_port,
          protocol      = "tcp",
          name          = local.cubestore_worker_port_name
        }
      ],
      environment = [{
        name  = "CUBESTORE_SERVER_NAME"
        value = "${local.cubestore_worker_dns_prefix}-${count.index}:${local.cubestore_worker_port}"
        },
        {
          name  = "CUBESTORE_WORKER_PORT"
          value = "${local.cubestore_worker_port}"
        },
        {
          name  = "CUBESTORE_META_ADDR"
          value = "${local.cubestore_router_dns_name}:${local.cubestore_router_port}"
        },
        {
          name  = "CUBESTORE_WORKERS"
          value = "${local.cubestore_task_dns_names}"
        },
        {
          name  = "CUBESTORE_REMOTE_DIR"
          value = "/cube/data"
      }]
    }
  ])

}

