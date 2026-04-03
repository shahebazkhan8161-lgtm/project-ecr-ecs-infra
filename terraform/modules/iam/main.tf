data "aws_caller_identity" "current" {}

# ── GitHub OIDC Provider ──────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── IAM Role — GitHub Actions assume karega ──────────
resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Sirf specific repo + branch assume kar sakti hai
          "token.actions.githubusercontent.com:sub" = var.allowed_subjects
        }
      }
    }]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── IAM Policy ────────────────────────────────────────
resource "aws_iam_policy" "github_actions" {
  name        = "${var.project}-github-actions-policy-${var.environment}"
  description = "GitHub Actions permissions for ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ECR
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:TagResource"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project}-*"
      },

      # ECS
      {
        Sid    = "ECS"
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },

      # IAM PassRole — ECS task execution role ke liye
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:TagRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagPolicy"
        ]
        Resource = "*"
      },

      # VPC + Networking
      {
        Sid      = "VPC"
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      },

      # ALB
      {
        Sid      = "ELB"
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:*"]
        Resource = "*"
      },

      # ACM — SSL certificate ke liye (domain ke liye zaroori)
      {
        Sid    = "ACM"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:DeleteCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:GetCertificate"
        ]
        Resource = "*"
      },

      # Route53 — domain shabaz.mytitan.in ke liye
      {
        Sid    = "Route53"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:GetChange",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone"
        ]
        Resource = "*"
      },

      # RDS
      {
        Sid    = "RDS"
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:AddTagsToResource",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },

      # S3 — Terraform state (s3-ecr-ecs-bucket)
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:CreateBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketEncryption",
          "s3:PutBucketTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.tf_state_bucket}",
          "arn:aws:s3:::${var.tf_state_bucket}/*"
        ]
      },

      # DynamoDB — Terraform lock (dynamo-ecr-ecs-table)
      {
        Sid    = "TerraformLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:CreateTable",
          "dynamodb:TagResource"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.tf_lock_table}"
      },

      # CloudWatch Logs
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:ListTagsLogGroup",
          "logs:TagLogGroup"
        ]
        Resource = "*"
      },

      # Secrets Manager
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:TagResource"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
