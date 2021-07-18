output "ecs_cluster_name" {
  value = aws_ecs_cluster.default.name
  description = "The name of the ECS cluster"
}

output "ecs_cluster_alb_arn" {
  value = aws_alb.ecs_cluster_alb.arn
  description = "THe arn of the ECS cluster's ALB"
}

output "ecs_cluster_alb_https_listener_arn" {
  value = aws_alb_listener.ecs_alb_https_listener.arn
}

output "namespace_id" {
  value       = aws_service_discovery_private_dns_namespace.default.id
  description = "The namespace id of the private dns namespace"
}