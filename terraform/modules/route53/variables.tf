variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "root_domain" {
  description = "Root domain — hosted zone ka naam"
  type        = string
  default     = "mytitan.in"
}

variable "domain_name" {
  description = "Full subdomain — shabaz.mytitan.in"
  type        = string
  default     = "shabaz.mytitan.in"
}

variable "alb_dns_name" {
  description = "ALB DNS name — health check ke liye"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain — A record yahan point karega"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID — Route53 alias ke liye zaroori"
  type        = string
}

variable "enable_health_check" {
  description = "Route53 health check enable karo ya nahi"
  type        = bool
  default     = false
}
