output "backend_repo_url" {
  description = "Backend ECR repo URL — Docker push ke liye"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_url" {
  description = "Frontend ECR repo URL — Docker push ke liye"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_repo_name" {
  description = "Backend ECR repo name"
  value       = aws_ecr_repository.backend.name
}

output "frontend_repo_name" {
  description = "Frontend ECR repo name"
  value       = aws_ecr_repository.frontend.name
}
