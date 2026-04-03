# ── WAF Web ACL ───────────────────────────────────────
# CloudFront ke saath attach hota hai
# IMPORTANT: CloudFront WAF hamesha us-east-1 mein banana padta hai
# Isliye yeh module us-east-1 provider use karta hai

resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "${var.project}-waf-${var.environment}"
  description = "WAF for ${var.project} ${var.environment} — CloudFront protection"
  scope       = "CLOUDFRONT"   # ALB ke liye "REGIONAL" hota, CloudFront ke liye "CLOUDFRONT"

  default_action {
    allow {}   # Default allow — rules jo match karein woh block/count honge
  }

  # ── Rule 1: AWS Managed — Common Rules ───────────────
  # OWASP Top 10 common vulnerabilities cover karta hai
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}   # Rules ki default action use karo (block)
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Size constraint rules override karo — large body requests allow karne ke liye
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}   # Block mat karo, sirf count karo
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-common-rules-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 2: AWS Managed — Known Bad Inputs ────────────
  # Log4j, Spring4Shell etc. known exploits block karta hai
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-bad-inputs-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 3: AWS Managed — SQL Injection ──────────────
  # SQL injection attacks block karta hai
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-sqli-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 4: Rate Limiting ─────────────────────────────
  # Ek IP se zyada requests aaye toh block karo
  # API abuse aur brute force attacks rokta hai
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5min
        aggregate_key_type = "IP"

        # Sirf /api/* pe rate limit lagao — static files pe nahi
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "/api/"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-rate-limit-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 5: Geo Blocking (optional) ──────────────────
  # Specific countries block karo — production ke liye useful
  # Default mein disabled hai — var.blocked_countries empty hai
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []

    content {
      name     = "GeoBlockRule"
      priority = 5

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project}-geo-block-${var.environment}"
        sampled_requests_enabled   = true
      }
    }
  }

  # ── Rule 6: IP Allowlist for Admin paths ─────────────
  # /admin/* sirf allowed IPs se access ho
  dynamic "rule" {
    for_each = length(var.admin_allowed_ips) > 0 ? [1] : []

    content {
      name     = "AdminIPAllowlist"
      priority = 6

      action {
        block {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              field_to_match {
                uri_path {}
              }
              positional_constraint = "STARTS_WITH"
              search_string         = "/admin"
              text_transformation {
                priority = 0
                type     = "LOWERCASE"
              }
            }
          }

          statement {
            not_statement {
              statement {
                ip_set_reference_statement {
                  arn = aws_wafv2_ip_set.admin_allowlist[0].arn
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project}-admin-allowlist-${var.environment}"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-waf-${var.environment}"
    sampled_requests_enabled   = true
  }
}

# ── Admin IP Set ──────────────────────────────────────
# Admin allowed IPs ka set — sirf tab banao jab IPs diye hon

resource "aws_wafv2_ip_set" "admin_allowlist" {
  provider           = aws.us_east_1
  count              = length(var.admin_allowed_ips) > 0 ? 1 : 0
  name               = "${var.project}-admin-ips-${var.environment}"
  description        = "Admin paths ke liye allowed IP addresses"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.admin_allowed_ips

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── WAF Logging ───────────────────────────────────────
# WAF logs S3 mein store karo — security audit ke liye
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  # Successful requests log mat karo — sirf blocked/counted
  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
      requirement = "MEETS_ANY"
    }

    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "COUNT"
        }
      }
      requirement = "MEETS_ANY"
    }
  }
}

# ── CloudWatch Log Group for WAF ──────────────────────
# WAF logs ka naam "aws-waf-logs-" se start hona chahiye — AWS requirement
resource "aws_cloudwatch_log_group" "waf" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project}-${var.environment}"
  retention_in_days = var.environment == "production" ? 30 : 7

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
