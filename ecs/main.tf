locals {
  name = "alhardynet"
}

resource "aws_ecs_cluster" "this" {
  name = local.name
}