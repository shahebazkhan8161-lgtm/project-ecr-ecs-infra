output "app_url" {
  description = "Live application URL — https://shabaz.mytitan.in"
  value       = module.route53.app_url
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — cache invalidation ke liye"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "alb_dns_name" {
  description = "ALB DNS name — direct access ke liye (not recommended)"
  value       = module.ecs.alb_dns_name
}

output "github_actions_role_arn" {
  description = "Yeh ARN GitHub Secrets mein daalo — DEV/UAT/PROD_IAM_ROLE_ARN"
  value       = module.iam.github_actions_role_arn
}

output "ecr_backend_url" {
  description = "Backend ECR repository URL"
  value       = module.ecr.backend_repo_url
}

output "ecr_frontend_url" {
  description = "Frontend ECR repository URL"
  value       = module.ecr.frontend_repo_url
}

output "db_endpoint" {
  description = "RDS Postgres endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs.cluster_name
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.web_acl_arn
}

output "waf_log_group" {
  description = "WAF CloudWatch log group — blocked requests yahan dikhenge"
  value       = module.waf.log_group_name
}
