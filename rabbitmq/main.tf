data "aws_secretsmanager_secret_version" "mq_admin" {
  secret_id = "platform/mq/admin"
}

locals {
  admin_creds = jsondecode(data.aws_secretsmanager_secret_version.mq_admin.secret_string)
}

resource "aws_security_group" "this" {
  name        = "${local.name}-SG"
  description = "Security group for customer api to communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name               = "${local.name}-SG"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_security_group_rule" "mq_ports_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, data.terraform_remote_state.hub.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "mq_ports_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_mq_broker" "this" {
  broker_name                = local.name
  publicly_accessible        = false
  deployment_mode            = "CLUSTER_MULTI_AZ"
  auto_minor_version_upgrade = true
  engine_type                = "RabbitMQ"
  engine_version             = "3.8.17"
  host_instance_type         = "mq.m5.large"
  subnet_ids                 = data.terraform_remote_state.vpc.outputs.private_persistence_subnets
  security_groups            = [aws_security_group.this.id]
  apply_immediately          = true // TODO: Should be during maintenance window in real work so set to false

  maintenance_window_start_time {
    day_of_week = var.maintenance_day_of_week
    time_of_day = var.maintenance_time_of_day
    time_zone   = var.maintenance_time_zone
  }

  // TODO
  //  encryption_options {
  //    kms_key_id = arn
  //    use_aws_owned_key = true
  //  }

  logs {
    general = true
  }

  user {
    username       = local.admin_creds.username
    password       = local.admin_creds.password
    groups         = ["admin"]
    console_access = true
  }
}