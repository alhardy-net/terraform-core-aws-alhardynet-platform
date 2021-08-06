resource "aws_appmesh_mesh" "this" {
  name = var.appmesh_name

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}