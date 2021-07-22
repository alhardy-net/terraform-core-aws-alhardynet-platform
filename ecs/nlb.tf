resource "aws_alb" "ecs_cluster_nlb" {
  name               = "${local.name}-nlb"
  internal           = false
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnets
  load_balancer_type = "network"

  tags = {
    Name               = "${local.name}-nlb"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_alb_target_group" "ecs_nlb_default_group" {
  name        = "${local.name}-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name               = "${local.name}-ecs-default"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }

  depends_on = [aws_alb.ecs_cluster_nlb]
}

resource "aws_alb_listener" "ecs_nlb_https_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_nlb.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.ecs_domain_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_nlb_default_group.arn
  }

  depends_on = [aws_alb_target_group.ecs_nlb_default_group]
}

resource "aws_route53_record" "ecs_nlb_record" {
  name    = var.ecs_nlb_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.ecs_domain.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_alb.ecs_cluster_nlb.dns_name
    zone_id                = aws_alb.ecs_cluster_nlb.zone_id
  }
}