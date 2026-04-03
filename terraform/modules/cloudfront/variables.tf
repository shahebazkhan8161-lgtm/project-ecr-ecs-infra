variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "domain_name" {
  description = "Full domain — shabaz.mytitan.in"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name — CloudFront origin yahan point karega"
  type        = string
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN — us-east-1 mein hona chahiye (CloudFront requirement)"
  type        = string
}

variable "cert_validation_fqdns" {
  description = "Certificate validation FQDNs — Route53 se aate hain"
  type        = list(string)
  default     = []
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN — waf module se aata hai (us-east-1 mein hona chahiye)"
  type        = string
  default     = null   # null = WAF disabled (dev mein use karo)
}
