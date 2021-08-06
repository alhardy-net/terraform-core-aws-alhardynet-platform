output "ecs_cluster_name" {
  value       = aws_ecs_cluster.default.name
  description = "The name of the ECS cluster"
}

output "ecs_cluster_nlb_arn" {
  value       = aws_alb.ecs_cluster_nlb.arn
  description = "THe arn of the ECS cluster's NLB"
}

output "ecs_cluster_nlb_https_listener_arn" {
  value = aws_alb_listener.ecs_nlb_https_listener.arn
}

output "namespace_id" {
  value       = aws_service_discovery_private_dns_namespace.default.id
  description = "The namespace id of the private dns namespace"
}

output "namespace_hostname" {
  value       = var.private_namespace
  description = "The hostname of the private dns namespace"
}

output "cluster_name" {
  value       = aws_ecs_cluster.default.name
  description = "The name of the ecs cluster"
}

output "appmesh_name" {
  value       = aws_appmesh_mesh.this.name
  description = "The name of the App Mesh used for the ECS Cluster"
}

output "appmesh_arn" {
  value       = aws_appmesh_mesh.this.arn
  description = "The arn of the App Mesh used for the ECS Cluster"
}

output "appmesh_virtual_gateway_name" {
  value       = aws_appmesh_virtual_gateway.this.name
  description = "The name of the App Mesh Virtual Gateway"
}

output "service_discovery_private_dns_namespace_name" {
  value       = aws_service_discovery_private_dns_namespace.default.name
  description = "The name of private dns namespace name for service discovery"
}

output "service_discovery_private_dns_namespace_arn" {
  value       = aws_service_discovery_private_dns_namespace.default.arn
  description = "The arn of private dns namespace name for service discovery"
}

output "default_task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution_role.arn
  description = "The arn of the default task execution role"
}