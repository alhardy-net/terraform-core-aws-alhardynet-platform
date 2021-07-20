resource "aws_appmesh_mesh" "this" {
  name = "alhardynet"

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}