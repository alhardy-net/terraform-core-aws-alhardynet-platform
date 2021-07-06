resource "aws_alb" "ecs_cluster_alb" {
  name            = "${local.name}-api-ecs"
  internal        = false
  security_groups = [aws_security_group.ecs_alb_security_group.id]
  subnets         = data.terraform_remote_state.vpc.outputs.public_subnets

  tags = {
    Name               = "${local.name}-api-ecs"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_alb_target_group" "ecs_default_target_group" {
  name     = "${local.name}-ecs-default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name               = "${local.name}-ecs-default"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}