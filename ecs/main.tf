resource "aws_ecs_cluster" "default" {
  name               = local.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  tags = {
    Name               = local.name
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}