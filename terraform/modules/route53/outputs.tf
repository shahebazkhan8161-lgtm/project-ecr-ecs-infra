output "zone_id" {
  value = data.aws_route53_zone.root.zone_id
}
output "app_fqdn" {
  value = aws_route53_record.app_cloudfront.fqdn
}
output "app_url" {
  value = "https://${var.domain_name}"
}
