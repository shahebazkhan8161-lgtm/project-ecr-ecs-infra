output "certificate_arn" {
  value = aws_acm_certificate_validation.alb.certificate_arn
}
output "cert_validation_fqdns" {
  value = [for r in aws_route53_record.validation : r.fqdn]
}
