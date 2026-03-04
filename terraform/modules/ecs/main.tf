locals {
  service_name          = "${var.project_name}-service"
  cluster_name          = "${var.project_name}-cluster"
  backend_environment   = [for key, value in var.backend_env : { name = key, value = value }]
  backend_secret_values = [for key, value in var.backend_secrets : { name = key, valueFrom = value }]
  frontend_environment  = [for key, value in var.frontend_env : { name = key, value = value }]
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution_secrets" {
  count = length(var.backend_secret_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowReadBackendSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.backend_secret_arns
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = length(var.backend_secret_arns) > 0 ? 1 : 0

  name   = "${var.project_name}-ecs-task-execution-secrets"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_task_execution_secrets[0].json
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = var.backend_container_name
      image     = var.backend_image
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = concat(local.backend_environment, [
        {
          name  = "PORT"
          value = tostring(var.backend_container_port)
        }
      ])
      secrets = local.backend_secret_values
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = var.frontend_container_name
      image     = var.frontend_image
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]
      environment = local.frontend_environment
      dependsOn = [
        {
          containerName = var.backend_container_name
          condition     = "START"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  deployment_controller {
    type = var.deployment_controller_type
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  network_configuration {
    assign_public_ip = var.assign_public_ip
    subnets          = var.subnet_ids
    security_groups  = [var.service_security_group_id]
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = var.frontend_container_name
    container_port   = var.frontend_container_port
  }

  load_balancer {
    target_group_arn = var.backend_metrics_target_group_arn
    container_name   = var.backend_container_name
    container_port   = var.backend_container_port
  }

  tags = var.tags
}
