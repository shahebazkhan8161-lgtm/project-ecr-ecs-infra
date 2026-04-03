output "alb_dns_name" {
  description = "ALB DNS name — CloudFront origin yahan point karega"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.main.zone_id
}

output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "backend_service_name" {
  description = "ECS Backend service name"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "ECS Frontend service name"
  value       = aws_ecs_service.frontend.name
}
