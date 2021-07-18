resource "aws_service_discovery_private_dns_namespace" "default" {
  name = var.private_namespace
  vpc  = data.terraform_remote_state.vpc.outputs.vpc_id
}