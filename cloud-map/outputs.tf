output "namespace_id" {
  value       = aws_service_discovery_private_dns_namespace.default.id
  description = "The namespace id of the private dns namespace"
}