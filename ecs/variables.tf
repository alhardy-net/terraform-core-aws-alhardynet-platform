variable "aws_region" {
  type        = string
  description = "The region of the hub vpc"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS Account Id of the hub account"
}

variable "aws_assume_role" {
  type        = string
  description = "The AWS Role to assume for the AWS account"
}

variable "ecs_nlb_domain_name" {
  type        = string
  description = "The domain name to associate to the NBL used by the ECS Cluster's virtual gateway"
}

variable "private_namespace" {
  type        = string
  description = "The service discovery private namespace name"
}

variable "appmesh_name" {
  type        = string
  description = "The name of the app mesh"
}

variable "envoy_image" {
  type        = string
  description = "The envoy image to use for the virtual gateway"
}

variable "xray_image" {
  type        = string
  description = "The xray image to use for tracing on virtual gateway"
}

variable "virtual_gateway" {
  type        = object({ service_name = string, cpu = number, memory = number, desired_count = number, max_percent = number, min_percent = number })
  description = "Configuration for the virtual gateway task and service"
}

# Terraform Cloud
variable "TFC_WORKSPACE_SLUG" {
  type        = string
  default     = "local"
  description = "This is the full slug of the configuration used in this run. This consists of the organization name and workspace name, joined with a slash"
}