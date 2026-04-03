variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones list"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}
