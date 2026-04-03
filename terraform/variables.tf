variable "project" {
  description = "Project name"
  type        = string
  default     = "ecr-ecs"
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-south-1"
}

# ── Network ───────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones list"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# ── Domain ────────────────────────────────────────────
variable "domain_name" {
  description = "Full application domain — shabaz.mytitan.in"
  type        = string
  default     = "shabaz.mytitan.in"
}

# ── Database ──────────────────────────────────────────
variable "db_name" {
  description = "Postgres database name"
  type        = string
}

variable "db_username" {
  description = "Postgres username"
  type        = string
}

variable "db_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

# ── Application ───────────────────────────────────────
variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker image tag — CI/CD se inject hoga"
  type        = string
  default     = "latest"
}

variable "backend_desired_count" {
  description = "ECS backend tasks count"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "ECS frontend tasks count"
  type        = number
  default     = 1
}

# ── OIDC ──────────────────────────────────────────────
variable "github_allowed_subjects" {
  description = "GitHub OIDC subjects — branch specific per environment"
  type        = list(string)
}

# ── WAF ───────────────────────────────────────────────
variable "waf_rate_limit" {
  description = "Rate limit — /api/* pe ek IP se 5 min mein max requests"
  type        = number
  default     = 1000
}

variable "waf_blocked_countries" {
  description = "Block karne wale countries — empty = koi block nahi"
  type        = list(string)
  default     = []
}

variable "waf_admin_allowed_ips" {
  description = "Admin paths ke liye allowed IPs — empty = disabled"
  type        = list(string)
  default     = []
}
