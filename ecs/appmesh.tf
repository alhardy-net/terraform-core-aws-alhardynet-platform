locals {
  virtual_gateway_name = "${var.appmesh_name}-vg"
}

resource "aws_appmesh_mesh" "this" {
  name = var.appmesh_name

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}

resource "aws_service_discovery_service" "envoy_proxy" {
  name = "virtual-gateway.${var.private_namespace}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.default.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_appmesh_virtual_gateway" "this" {
  name      = local.virtual_gateway_name
  mesh_name = aws_appmesh_mesh.this.name

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }

      health_check {
        port                = 80
        protocol            = "http"
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }
  }
}

resource "aws_ecs_task_definition" "envoy" {
  family = "virtual-gateway"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  task_role_arn      = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = jsonencode([
    {
      name      = "envoy"
      image     = var.envoy_image
      essential = true
      environment = [
        {
          name  = "APPMESH_VIRTUAL_NODE_NAME",
          value = "mesh/${var.appmesh_name}/virtualGateway/${local.virtual_gateway_name}"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
        {
          containerPort = 9901
          hostPort      = 9901
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        retries     = 3
        timeout     = 2
        interval    = 5
        startPeriod = 60
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ]
      }
    }
  ])
    lifecycle {
      ignore_changes = all
    }
}

resource "aws_security_group" "virtual_gateway" {
  name        = "${var.virtual_gateway_service_name}-SG"
  description = "Security group for service to communicate in and out of the virtual gateway"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.virtual_gateway_service_name}-SG"
  }
}

resource "aws_security_group_rule" "virtual_gateway_rules" {
  type              = "ingress"
  from_port         = 32768
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_ecs_service" "service" {
  name            = var.virtual_gateway_service_name
  cluster         = aws_ecs_cluster.default.name
  task_definition = aws_ecs_task_definition.envoy.arn
  desired_count   = 1

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_application_subnets
    security_groups  = [aws_security_group.virtual_gateway.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_nlb_default_group.arn
    container_name   = "envoy"
    container_port   = 80
  }

  service_registries {
    registry_arn = aws_service_discovery_service.envoy_proxy.arn
  }

  health_check_grace_period_seconds = 120

  deployment_controller {
    type = "ECS"
  }
  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

    lifecycle {
      ignore_changes = [task_definition]
    }
}