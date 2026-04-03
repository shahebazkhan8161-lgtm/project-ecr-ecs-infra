output "web_acl_arn" {
  description = "WAF Web ACL ARN — CloudFront module ko pass karo"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_capacity" {
  description = "WAF rules ki total capacity (max 1500)"
  value       = aws_wafv2_web_acl.main.capacity
}

output "log_group_name" {
  description = "CloudWatch log group name for WAF logs"
  value       = aws_cloudwatch_log_group.waf.name
}
