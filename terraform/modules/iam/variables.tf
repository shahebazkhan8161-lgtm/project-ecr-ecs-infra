variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "tf_state_bucket" {
  description = "S3 bucket — s3-ecr-ecs-bucket"
  type        = string
}

variable "tf_lock_table" {
  description = "DynamoDB table — dynamo-ecr-ecs-table"
  type        = string
}

variable "allowed_subjects" {
  description = "GitHub OIDC subjects — konsi branch role assume kar sakti hai"
  type        = list(string)
}
