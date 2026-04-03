output "github_actions_role_arn" {
  description = "Yeh ARN GitHub Secrets mein daalo — DEV/UAT/PROD_IAM_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM Role name"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "GitHub OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}
