output "cloudfront_domain_name" {
  description = "CloudFront distribution domain — Route53 CNAME yahan point karega"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — cache invalidation ke liye"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID — Route53 alias record ke liye"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN in us-east-1"
  value       = aws_acm_certificate.cloudfront.arn
}
