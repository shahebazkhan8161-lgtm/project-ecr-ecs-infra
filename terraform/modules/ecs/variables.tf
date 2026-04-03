variable "project"                {}
variable "environment"            {}
variable "aws_region"             { default = "ap-south-1" }
variable "vpc_id"                 {}
variable "public_subnet_ids"      {}
variable "private_subnet_ids"     {}
variable "backend_image"          {}
variable "frontend_image"         {}
variable "image_tag"              { default = "latest" }
variable "db_host"                {}
variable "db_name"                {}
variable "db_username"            {}
variable "db_password"            { sensitive = true }
variable "jwt_secret"             { sensitive = true }
variable "backend_desired_count"  { default = 1 }
variable "frontend_desired_count" { default = 1 }

variable "domain_name" {
  description = "Application domain — shabaz.mytitan.in"
  type        = string
  default     = "shabaz.mytitan.in"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB — route53 module se aata hai (ap-south-1)"
  type        = string
}
