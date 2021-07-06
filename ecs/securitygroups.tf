resource "aws_security_group" "ecs_security_group" {
  name        = "${local.name}-ecs-public"
  description = "Security group for ECS to communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 32768
    protocol    = "TCP"
    to_port     = 65535
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name               = "${local.name}-ecs-public"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_security_group" "ecs_alb_security_group" {
  name        = "${local.name}-alb-public"
  description = "Security group for ALB to traffic for ECS cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name               = "${local.name}-alb-public"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}