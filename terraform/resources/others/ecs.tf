####################################################
# ECS Cluster
####################################################

resource "aws_ecs_cluster" "this" {
  name = "${local.app_name}-app-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this_capacity_providers" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

####################################################
# ECS IAM Role
####################################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

####################################################
# ECS Task Container Log Groups
####################################################

resource "aws_cloudwatch_log_group" "backend_app" {
  name              = "/ecs/${local.app_name}/backend/app"
  retention_in_days = 30
}

####################################################
# ECS Task Definition
####################################################
locals {
  backend_task_name               = "${local.app_name}-app-task-backend"
  backend_task_app_container_name = "${local.app_name}-app-container-backend"
  backend_image                   = "146161350821.dkr.ecr.ap-northeast-1.amazonaws.com/experiment-app:latest"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = local.backend_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name         = local.backend_task_app_container_name
      image        = local.backend_image
      secrets      = []
      portMappings = [{ containerPort : 3000 }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.backend_app.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name                               = "${local.app_name}-backend"
  cluster                            = aws_ecs_cluster.this.id
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.backend.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    assign_public_ip = true
    subnets = [
      var.public_1a_subnet_id,
      //aws_subnet.public_1c.id,
    ]
    security_groups = [
      aws_security_group.app.id,
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = local.backend_task_app_container_name
    container_port   = 3000
  }
  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition
    ]
  }
}

resource "aws_lb_target_group" "backend" {
  name                 = "${local.app_name}-service-tg-baackend"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  port                 = 3000
  protocol             = "HTTP"
  deregistration_delay = 60
}

locals {
  tennant_id = "b793ec89-65af-45e6-81a6-6bd333bfa72b"
  client_id  = "3bd4dcbd-7c99-4893-96e9-779bc4166c10"
}

resource "aws_lb_listener_rule" "backend_https_oidc_login" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2
  action {
    type = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = "https://login.microsoftonline.com/${local.tennant_id}/oauth2/v2.0/authorize"
      client_id                  = local.client_id
      client_secret              = aws_ssm_parameter.client_secret.value
      issuer                     = "https://login.microsoftonline.com/${local.tennant_id}/v2.0"
      token_endpoint             = "https://login.microsoftonline.com/${local.tennant_id}/oauth2/v2.0/token"
      user_info_endpoint         = "https://graph.microsoft.com/oidc/userinfo"
      scope                      = "user.read openid email profile"
      on_unauthenticated_request = "authenticate"
      session_timeout = 30
    }
  }
  //action {
  //  type = "redirect"
  //  redirect {
  //    status_code = "HTTP_301"
  //    path = "/"
  //  }
  //}
  // action {
  //   type             = "fixed-response"
  //   // target_group_arn = aws_lb_target_group.backend.arn
  //   fixed_response {
  //     content_type = "text/plain"
  //     message_body = "LOGIN!"
  //     status_code  = "200"
  //   }
  // }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["/api/login"]
    }
  }
}

resource "aws_lb_listener_rule" "backend_https_oidc" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  action {
    type = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = "https://login.microsoftonline.com/${local.tennant_id}/oauth2/v2.0/authorize"
      client_id                  = local.client_id
      client_secret              = aws_ssm_parameter.client_secret.value
      issuer                     = "https://login.microsoftonline.com/${local.tennant_id}/v2.0"
      token_endpoint             = "https://login.microsoftonline.com/${local.tennant_id}/oauth2/v2.0/token"
      user_info_endpoint         = "https://graph.microsoft.com/oidc/userinfo"
      scope                      = "user.read openid email profile"
      on_unauthenticated_request = "deny"
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_ssm_parameter" "client_secret" {
  name  = "client_secret"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
