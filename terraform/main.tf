terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "s3-ecr-ecs-bucket"
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "dynamo-ecr-ecs-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "iam" {
  source           = "./modules/iam"
  project          = var.project
  environment      = var.environment
  aws_region       = var.aws_region
  tf_state_bucket  = "s3-ecr-ecs-bucket"
  tf_lock_table    = "dynamo-ecr-ecs-table"
  allowed_subjects = var.github_allowed_subjects
}

module "vpc" {
  source             = "./modules/vpc"
  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ecr" {
  source      = "./modules/ecr"
  project     = var.project
  environment = var.environment
}

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

module "route53" {
  source      = "./modules/route53"
  project     = var.project
  environment = var.environment
  root_domain = "shabaz.mytitan.in"
  domain_name = var.domain_name
  alb_dns_name              = module.ecs.alb_dns_name
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  enable_health_check       = var.environment == "production"
  depends_on = [module.ecs, module.cloudfront]
}

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
  alb_certificate_arn    = module.ecs_cert.certificate_arn
  backend_desired_count  = var.backend_desired_count
  frontend_desired_count = var.frontend_desired_count
}

module "ecs_cert" {
  source      = "./modules/acm_regional"
  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  root_domain = "shabaz.mytitan.in"
}

module "waf" {
  source              = "./modules/waf"
  project             = var.project
  environment         = var.environment
  rate_limit_per_5min = var.waf_rate_limit
  blocked_countries   = var.waf_blocked_countries
  admin_allowed_ips   = var.waf_admin_allowed_ips
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

module "cloudfront" {
  source                        = "./modules/cloudfront"
  project                       = var.project
  environment                   = var.environment
  domain_name                   = var.domain_name
  alb_dns_name                  = module.ecs.alb_dns_name
  acm_certificate_arn_us_east_1 = module.cloudfront.acm_certificate_arn_us_east_1
  waf_web_acl_arn               = module.waf.web_acl_arn
  cert_validation_fqdns         = []
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  depends_on = [module.ecs, module.waf]
}

