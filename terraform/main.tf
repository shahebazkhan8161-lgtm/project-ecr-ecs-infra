terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — s3-ecr-ecs-bucket + dynamo-ecr-ecs-table
  backend "s3" {
    bucket         = "s3-ecr-ecs-bucket"
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "dynamo-ecr-ecs-table"
    encrypt        = true
  }
}

# ── Provider ap-south-1 (default) ────────────────────
provider "aws" {
  region = var.aws_region
}

# ── Provider us-east-1 (CloudFront certificate) ───────
# CloudFront sirf us-east-1 mein ACM certificate accept karta hai
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ── MODULE 1 — IAM (OIDC + GitHub Actions Role) ───────
module "iam" {
  source      = "./modules/iam"
  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  tf_state_bucket  = "s3-ecr-ecs-bucket"
  tf_lock_table    = "dynamo-ecr-ecs-table"
  allowed_subjects = var.github_allowed_subjects
}

# ── MODULE 2 — VPC ────────────────────────────────────
module "vpc" {
  source             = "./modules/vpc"
  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ── MODULE 3 — ECR ────────────────────────────────────
module "ecr" {
  source      = "./modules/ecr"
  project     = var.project
  environment = var.environment
}

# ── MODULE 4 — RDS ────────────────────────────────────
module "rds" {
  source             = "./modules/rds"
  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
}

# ── MODULE 5 — ECS (ALB + Fargate services) ───────────
# Route53 se certificate ARN aata hai — isliye route53 pehle banana chahiye
module "ecs" {
  source                 = "./modules/ecs"
  project                = var.project
  environment            = var.environment
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  backend_image          = module.ecr.backend_repo_url
  frontend_image         = module.ecr.frontend_repo_url
  image_tag              = var.image_tag
  db_host                = module.rds.db_endpoint
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  jwt_secret             = var.jwt_secret
  domain_name            = var.domain_name
  alb_certificate_arn    = module.route53.alb_certificate_arn
  backend_desired_count  = var.backend_desired_count
  frontend_desired_count = var.frontend_desired_count

  depends_on = [module.route53]
}

# ── MODULE 6 — Route53 (DNS + ACM ap-south-1) ─────────
# ALB ke liye DNS records + certificate
# CloudFront pe point karta hai — isliye cloudfront pehle banana chahiye
module "route53" {
  source      = "./modules/route53"
  project     = var.project
  environment = var.environment

  root_domain               = "mytitan.in"
  domain_name               = var.domain_name
  alb_dns_name              = module.ecs.alb_dns_name
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  enable_health_check       = var.environment == "production"

  depends_on = [module.ecs, module.cloudfront]
}

# ── MODULE 7 — WAF (Web Application Firewall) ────────
# CloudFront ke saath attach hota hai
# us-east-1 mein banana padta hai — CloudFront requirement
module "waf" {
  source      = "./modules/waf"
  project     = var.project
  environment = var.environment

  rate_limit_per_5min = var.waf_rate_limit
  blocked_countries   = var.waf_blocked_countries
  admin_allowed_ips   = var.waf_admin_allowed_ips

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

# ── MODULE 8 — CloudFront (CDN + HTTPS + caching) ─────
# Frontend static files cache karta hai globally
# Backend /api/* requests seedha ALB pe forward karta hai
module "cloudfront" {
  source      = "./modules/cloudfront"
  project     = var.project
  environment = var.environment

  domain_name                   = var.domain_name
  alb_dns_name                  = module.ecs.alb_dns_name
  acm_certificate_arn_us_east_1 = module.cloudfront.acm_certificate_arn_us_east_1
  cert_validation_fqdns         = module.route53.cert_validation_fqdns
  waf_web_acl_arn               = module.waf.web_acl_arn

  providers = {
    aws            = aws
    aws.us_east_1  = aws.us_east_1
  }

  depends_on = [module.ecs, module.waf]
}
