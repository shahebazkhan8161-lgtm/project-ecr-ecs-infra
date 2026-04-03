output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.root.zone_id
}

output "app_fqdn" {
  description = "Application FQDN — shabaz.mytitan.in"
  value       = aws_route53_record.app_cloudfront.fqdn
}

output "app_url" {
  description = "Full application URL"
  value       = "https://${var.domain_name}"
}

output "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB (ap-south-1)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "cert_validation_fqdns" {
  description = "Certificate validation FQDNs — CloudFront module ko pass karo"
  value       = [for r in aws_route53_record.acm_validation : r.fqdn]
}
