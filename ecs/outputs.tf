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