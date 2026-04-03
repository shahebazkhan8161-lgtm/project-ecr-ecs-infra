#!/bin/bash
# ─────────────────────────────────────────────────────
# Bootstrap Script — Pehli baar chalao
# S3 bucket + DynamoDB table banata hai Terraform state ke liye
# ─────────────────────────────────────────────────────

set -e

AWS_REGION="ap-south-1"
S3_BUCKET="s3-ecr-ecs-bucket"
DYNAMO_TABLE="dynamo-ecr-ecs-table"

echo ""
echo "=== Project ECR-ECS Bootstrap ==="
echo "Region : $AWS_REGION"
echo "S3     : $S3_BUCKET"
echo "DynamoDB: $DYNAMO_TABLE"
echo ""

# ── Step 1: S3 Bucket ─────────────────────────────────
echo "[1/4] Creating S3 bucket: $S3_BUCKET ..."

aws s3api create-bucket \
  --bucket "$S3_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

echo "      Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$S3_BUCKET" \
  --versioning-configuration Status=Enabled

echo "      Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket "$S3_BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "      Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$S3_BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "      Tagging bucket..."
aws s3api put-bucket-tagging \
  --bucket "$S3_BUCKET" \
  --tagging 'TagSet=[{Key=Project,Value=ecr-ecs},{Key=ManagedBy,Value=bootstrap}]'

echo "   S3 bucket created."

# ── Step 2: DynamoDB Table ────────────────────────────
echo ""
echo "[2/4] Creating DynamoDB table: $DYNAMO_TABLE ..."

aws dynamodb create-table \
  --table-name "$DYNAMO_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" \
  --tags Key=Project,Value=ecr-ecs Key=ManagedBy,Value=bootstrap

echo "   DynamoDB table created."

# ── Step 3: Verify ────────────────────────────────────
echo ""
echo "[3/4] Verifying resources..."

S3_STATUS=$(aws s3api get-bucket-versioning --bucket "$S3_BUCKET" --query 'Status' --output text)
echo "   S3 Versioning : $S3_STATUS"

DYNAMO_STATUS=$(aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --query 'Table.TableStatus' --output text --region "$AWS_REGION")
echo "   DynamoDB Status: $DYNAMO_STATUS"

# ── Step 4: Print next steps ──────────────────────────
echo ""
echo "[4/4] Bootstrap complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " 1. terraform/envs/*.tfvars mein YOUR-ORG replace karo"
echo "    apne actual GitHub organization name se"
echo ""
echo " 2. Terraform se IAM + OIDC banao:"
echo "    cd terraform"
echo "    terraform init -backend-config='key=dev/terraform.tfstate' \\"
echo "      -backend-config='bucket=$S3_BUCKET' \\"
echo "      -backend-config='dynamodb_table=$DYNAMO_TABLE' \\"
echo "      -backend-config='region=$AWS_REGION'"
echo "    terraform apply -var-file=envs/dev.tfvars \\"
echo "      -var='db_password=yourpass' \\"
echo "      -var='jwt_secret=yoursecret'"
echo ""
echo " 3. terraform output github_actions_role_arn"
echo "    Is ARN ko GitHub Secrets mein daalo:"
echo "    - DEV_IAM_ROLE_ARN  (frontend + backend + infra repos)"
echo "    - UAT_IAM_ROLE_ARN"
echo "    - PROD_IAM_ROLE_ARN"
echo ""
echo " 4. GitHub Secrets set karo (teeno repos mein):"
echo "    DEV_IAM_ROLE_ARN      = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-dev"
echo "    UAT_IAM_ROLE_ARN      = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-uat"
echo "    PROD_IAM_ROLE_ARN     = arn:aws:iam::ACCOUNT:role/ecr-ecs-github-actions-production"
echo "    DEV_DB_PASSWORD       = your-dev-db-password"
echo "    UAT_DB_PASSWORD       = your-uat-db-password"
echo "    PROD_DB_PASSWORD      = your-prod-db-password"
echo "    DEV_JWT_SECRET        = your-dev-jwt-secret"
echo "    UAT_JWT_SECRET        = your-uat-jwt-secret"
echo "    PROD_JWT_SECRET       = your-prod-jwt-secret"
echo "    INFRA_DEPLOY_TOKEN    = GitHub PAT (frontend+backend repos ke liye)"
echo ""
echo " 5. GitHub → Settings → Environments:"
echo "    - dev        : no approval needed"
echo "    - uat        : required reviewers set karo"
echo "    - production : senior reviewers + optional wait timer"
echo ""
echo " 6. mytitan.in hosted zone Route53 mein hona chahiye"
echo "    shabaz.mytitan.in ACM certificate automatically validate hoga"
echo ""
echo " App: https://shabaz.mytitan.in"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
