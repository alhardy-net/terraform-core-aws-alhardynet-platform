locals {
  virtual_gateway_name = "${var.appmesh_name}-vg"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.virtual_gateway.service_name}"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${var.virtual_gateway.service_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
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

data "aws_ecs_task_definition" "virtual_gateway" {
  task_definition = aws_ecs_task_definition.virtual_gateway.family
}

resource "aws_ecs_task_definition" "virtual_gateway" {
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
      name  = "xray-daemon"
      image = var.xray_image
      portMappings = [
        {
          containerPort = 2000
          hostPort      = 2000
          protocol      = "udp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        secretOptions = null
        options = {
          awslogs-group = "/ecs/${var.virtual_gateway.service_name}"
          awslogs-region = "ap-southeast-2",
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "envoy"
      image     = var.envoy_image
      essential = true
      environment = [
        {
          name  = "APPMESH_VIRTUAL_NODE_NAME",
          value = "mesh/${var.appmesh_name}/virtualGateway/${local.virtual_gateway_name}"
        },
        {
          name  = "ENABLE_ENVOY_XRAY_TRACING",
          value = "1"
        },
        {
          name: "ENVOY_LOG_LEVEL",
          value: "info"
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
      },
      logConfiguration = {
        logDriver = "awslogs",
        secretOptions = null
        options = {
          awslogs-group = "/ecs/${var.virtual_gateway.service_name}"
          awslogs-region = "ap-southeast-2",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_security_group" "virtual_gateway" {
  name        = "${var.virtual_gateway.service_name}-SG"
  description = "Security group for service to communicate in and out of the virtual gateway"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${var.virtual_gateway.service_name}-SG"
  }
}

resource "aws_security_group_rule" "ephemeral_ports_ingress" {
  type              = "ingress"
  from_port         = 32768
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_security_group_rule" "virtual_gateway_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_ecs_service" "service" {
  name                               = var.virtual_gateway.service_name
  cluster                            = aws_ecs_cluster.default.name
  task_definition                    = "${aws_ecs_task_definition.virtual_gateway.family}:${max(aws_ecs_task_definition.virtual_gateway.revision, data.aws_ecs_task_definition.virtual_gateway.revision)}"
  desired_count                      = var.virtual_gateway.desired_count
  deployment_maximum_percent         = var.virtual_gateway.max_percent
  deployment_minimum_healthy_percent = var.virtual_gateway.min_percent

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
}