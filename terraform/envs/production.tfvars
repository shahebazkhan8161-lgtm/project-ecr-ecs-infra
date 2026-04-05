# ── PRODUCTION Environment ────────────────────────────
project     = "ecr-ecs"
environment = "production"
aws_region  = "ap-south-1"

# Network
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]

# Domain
domain_name = "shabaz.mytitan.in"

# Database — production mein multi-az ON
db_name           = "ecr_ecs_db"
db_username       = "postgres"
db_instance_class = "db.t3.small"

# ECS desired counts — production mein 2 tasks for HA
backend_desired_count  = 2
frontend_desired_count = 2

# OIDC — sirf main branch PROD role assume kar sakti hai
github_allowed_subjects = [
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-frontend:ref:refs/heads/main",
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-backend:ref:refs/heads/main",
  "repo:shahebazkhan8161-lgtm/project-ecr-ecs-infra:ref:refs/heads/main"
]

# Secrets — CI se inject honge
# db_password = set via TF_VAR_db_password
# jwt_secret  = set via TF_VAR_jwt_secret

# WAF — production mein strict settings
waf_rate_limit        = 500
waf_blocked_countries = []
waf_admin_allowed_ips = []
# Example allowed IPs for admin:
# waf_admin_allowed_ips = ["YOUR_OFFICE_IP/32"]
