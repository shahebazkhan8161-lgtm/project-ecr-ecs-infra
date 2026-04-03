# project-ecr-ecs-infra

Terraform infrastructure — AWS ECS Fargate, ECR, RDS, VPC, ALB, ACM, Route53.
Domain: **https://shabaz.mytitan.in**

## Resources Managed

| Resource         | Name / Value                  |
|------------------|-------------------------------|
| S3 State Bucket  | `s3-ecr-ecs-bucket`           |
| DynamoDB Lock    | `dynamo-ecr-ecs-table`        |
| Domain           | `shabaz.mytitan.in`           |
| Region           | `ap-south-1`                  |
| ECS Cluster      | `ecr-ecs-cluster-<env>`       |
| ECR Backend      | `ecr-ecs-backend`             |
| ECR Frontend     | `ecr-ecs-frontend`            |
| RDS              | `ecr-ecs-db-<env>` (Postgres) |
| ALB              | `ecr-ecs-alb-<env>`           |

## Module Structure

```
terraform/
├── main.tf                      # Root — saare modules call hote hain
├── variables.tf                 # Root variables
├── outputs.tf                   # Root outputs
├── envs/
│   ├── dev.tfvars               # DEV config
│   ├── uat.tfvars               # UAT config
│   └── production.tfvars        # PROD config
└── modules/
    ├── vpc/                     # VPC, subnets, NAT, IGW, route tables
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecr/                     # ECR repos + lifecycle policy
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds/                     # RDS Postgres instance
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                     # OIDC Provider + GitHub Actions IAM Role
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecs/                     # ECS Cluster, Services, ALB, ACM, Route53
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## First Time Setup

```bash
# 1. Bootstrap — S3 + DynamoDB banao (sirf ek baar)
chmod +x bootstrap.sh
./bootstrap.sh

# 2. YOUR-ORG replace karo envs/*.tfvars mein
sed -i 's/YOUR-ORG/actual-github-org/g' terraform/envs/*.tfvars

# 3. DEV infra banao
cd terraform
terraform init \
  -backend-config="bucket=s3-ecr-ecs-bucket" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="dynamodb_table=dynamo-ecr-ecs-table"

terraform apply \
  -var-file="envs/dev.tfvars" \
  -var="db_password=your-dev-password" \
  -var="jwt_secret=your-dev-secret"

# 4. Role ARN copy karo
terraform output github_actions_role_arn

# 5. Yeh ARN teeno repos ke GitHub Secrets mein daalo
```

## GitHub Secrets — Teeno repos mein set karo

```
DEV_IAM_ROLE_ARN    = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-dev
UAT_IAM_ROLE_ARN    = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-uat
PROD_IAM_ROLE_ARN   = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-production

DEV_DB_PASSWORD     = your-dev-db-pass
UAT_DB_PASSWORD     = your-uat-db-pass
PROD_DB_PASSWORD    = your-prod-db-pass

DEV_JWT_SECRET      = your-dev-jwt-secret
UAT_JWT_SECRET      = your-uat-jwt-secret
PROD_JWT_SECRET     = your-prod-jwt-secret

INFRA_DEPLOY_TOKEN  = GitHub PAT with repo scope
                      (frontend + backend repos infra repo ko trigger karte hain)
```

## Pipeline — Infra repo

```
frontend/backend repo push
         │
         ▼ (repository_dispatch event)
Infra repo trigger
         │
    ┌────┴─────────────────────┐
    ▼                          ▼
  DEV                        UAT/PROD
TF Init                      TF Init
TF Plan                      TF Plan
TF Apply (auto)              Approval Gate
                             TF Apply (after approval)
```

## Workflows

| File              | Branch    | Trigger                        | Approval |
|-------------------|-----------|--------------------------------|----------|
| dev.yml           | develop   | push + repository_dispatch     | No       |
| uat.yml           | staging   | push + repository_dispatch     | Yes      |
| production.yml    | main      | push + repository_dispatch     | Yes      |

## Environments — GitHub Settings mein configure karo

```
dev        → No approval required
uat        → Required reviewers: [team-lead, qa-engineer]
production → Required reviewers: [tech-lead, devops-engineer]
             Optional wait timer: 5 minutes
```

## State per environment

```
s3-ecr-ecs-bucket/
├── dev/terraform.tfstate
├── uat/terraform.tfstate
└── production/terraform.tfstate
```

## Domain Setup

```
mytitan.in hosted zone → Route53 mein hona chahiye
shabaz.mytitan.in      → ALB pe A record (Terraform banata hai)
SSL Certificate        → ACM se automatically validate hoga via DNS
```
