# ── DEV Environment ───────────────────────────────────
project     = "ecr-ecs"
environment = "dev"
aws_region  = "ap-south-1"

# Network
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]

# Domain
domain_name = "shabaz.mytitan.in"

# Database
db_name           = "ecr_ecs_db_dev"
db_username       = "postgres"
db_instance_class = "db.t3.micro"

# ECS desired counts
backend_desired_count  = 1
frontend_desired_count = 1

# OIDC — sirf develop branch DEV role assume kar sakti hai
github_allowed_subjects = [
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-frontend:*",
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-backend:*",
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-infra:*"
]

# Secrets — CI se inject honge (yahan mat likho)
# db_password = set via TF_VAR_db_password in GitHub Secrets
# jwt_secret  = set via TF_VAR_jwt_secret in GitHub Secrets

# WAF — dev mein rate limit zyada, koi country block nahi
waf_rate_limit        = 2000
waf_blocked_countries = []
waf_admin_allowed_ips = []
