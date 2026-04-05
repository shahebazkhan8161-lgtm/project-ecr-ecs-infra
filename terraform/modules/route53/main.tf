data "aws_route53_zone" "root" {
  name         = var.root_domain
  private_zone = false
}

resource "aws_route53_record" "app_cloudfront" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_cloudfront_ipv6" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.domain_name
  type    = "AAAA"
  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "alb" {
  count             = var.enable_health_check ? 1 : 0
  fqdn              = var.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  tags = {
    Name        = "${var.project}-hc-${var.environment}"
    Project     = var.project
    Environment = var.environment
  }
}
