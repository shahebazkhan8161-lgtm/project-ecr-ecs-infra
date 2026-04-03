variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "image_retention_count" {
  description = "Kitni images ECR mein rakhni hain"
  type        = number
  default     = 10
}
