# ── UAT Environment ───────────────────────────────────
project     = "ecr-ecs"
environment = "uat"
aws_region  = "ap-south-1"

# Network
vpc_cidr           = "10.2.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]

# Domain
domain_name = "shabaz.mytitan.in"

# Database
db_name           = "ecr_ecs_db_uat"
db_username       = "postgres"
db_instance_class = "db.t3.micro"

# ECS desired counts
backend_desired_count  = 1
frontend_desired_count = 1

# OIDC — sirf staging branch UAT role assume kar sakti hai
github_allowed_subjects = [
  "repo:YOUR-ORG/project-ecr-ecs-frontend:ref:refs/heads/staging",
  "repo:YOUR-ORG/project-ecr-ecs-backend:ref:refs/heads/staging",
  "repo:YOUR-ORG/project-ecr-ecs-infra:ref:refs/heads/staging"
]

# Secrets — CI se inject honge
# db_password = set via TF_VAR_db_password
# jwt_secret  = set via TF_VAR_jwt_secret

# WAF — uat mein moderate settings
waf_rate_limit        = 1000
waf_blocked_countries = []
waf_admin_allowed_ips = []
