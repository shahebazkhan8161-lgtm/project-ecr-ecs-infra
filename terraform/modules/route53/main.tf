# ── Data Source — existing hosted zone ───────────────
# mytitan.in hosted zone Route53 mein already honi chahiye
# Yah module existing zone use karta hai, naya nahi banata

data "aws_route53_zone" "root" {
  name         = var.root_domain
  private_zone = false
}

# ── ACM Certificate — ap-south-1 (ALB ke liye) ───────
# ALB ka certificate ap-south-1 mein hona chahiye

resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Usage       = "ALB"
  }
}

# ── DNS Validation Records — ACM ke liye ─────────────
# Yeh records ACM ko prove karta hai ki domain tumhara hai

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# ── A Record — shabaz.mytitan.in → CloudFront ─────────
# CloudFront distribution pe point karta hai (not ALB directly)
# Traffic CloudFront se ALB tak jaata hai

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

# ── AAAA Record — IPv6 support ────────────────────────
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

# ── Health Check — ALB ke liye ────────────────────────
resource "aws_route53_health_check" "alb" {
  count             = var.enable_health_check ? 1 : 0
  fqdn              = var.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name        = "${var.project}-health-check-${var.environment}"
    Project     = var.project
    Environment = var.environment
  }
}
