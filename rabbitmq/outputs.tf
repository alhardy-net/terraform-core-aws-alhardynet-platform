output "endpoint" {
  value       = aws_mq_broker.this.instances.0.endpoints
  description = "The rabbitmq endpoint url"
}