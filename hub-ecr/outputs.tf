output "registry_id" {
  value       = module.ecr.registry_id
  description = "Registry ID"
}

output "registry_url" {
  value       = module.ecr.repository_url_map
  description = "Repository URL"
}

output "repository_name" {
  value       = module.ecr.repository_arn_map
  description = "Registry name"
}