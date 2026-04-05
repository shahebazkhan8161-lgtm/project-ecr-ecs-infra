variable "project"                    { type = string }
variable "environment"                { type = string }
variable "root_domain" {
  type    = string
  default = "shabaz.mytitan.in"
}
variable "domain_name"               { type = string }
variable "alb_dns_name"              { type = string }
variable "cloudfront_domain_name"    { type = string }
variable "cloudfront_hosted_zone_id" { type = string }
variable "enable_health_check" {
  type    = bool
  default = false
}
