terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
# â”€â”€ CloudFront Distribution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Frontend static files globally cache honge
# Backend API requests directly ALB pe jaayenge

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project}-${var.environment}"
  default_root_object = "index.html"
  aliases             = [var.domain_name]

  # â”€â”€ Origin 1 â€” Frontend (ALB) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "frontend-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # â”€â”€ Origin 2 â€” Backend API (ALB /api/*) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "backend-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # â”€â”€ Cache Behavior â€” /api/* â†’ Backend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  # API requests cache nahi hone chahiye
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "backend-alb"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "Origin"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0     # API cache nahi karo
    max_ttl                = 0
    compress               = true
  }

  # â”€â”€ Cache Behavior â€” /health â†’ Backend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ordered_cache_behavior {
    path_pattern     = "/health"
    target_origin_id = "backend-alb"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # â”€â”€ Default Cache Behavior â€” Frontend static files â”€
  default_cache_behavior {
    target_origin_id = "frontend-alb"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1 din cache
    max_ttl                = 31536000 # 1 saal max
    compress               = true
  }

  # â”€â”€ SPA Support â€” 404/403 â†’ index.html â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  # React/SPA ke liye zaroori â€” client-side routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # â”€â”€ SSL Certificate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  # CloudFront ke liye certificate us-east-1 mein hona chahiye
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn_us_east_1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # â”€â”€ Geo Restriction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # â”€â”€ Price Class â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  # PriceClass_100 = US, Europe, Asia (cheapest)
  # PriceClass_All = global (expensive)
  price_class = var.environment == "production" ? "PriceClass_All" : "PriceClass_100"

  # WAF attach karo â€” waf module se ARN aata hai
  web_acl_id = var.waf_web_acl_arn

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# â”€â”€ ACM Certificate â€” us-east-1 (CloudFront ke liye) â”€
# CloudFront sirf us-east-1 certificates accept karta hai
# Isliye alag provider use karna padta hai
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = var.cert_validation_fqdns
}

