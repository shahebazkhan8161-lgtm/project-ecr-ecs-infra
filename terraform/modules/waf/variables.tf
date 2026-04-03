variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment — dev, uat, production"
  type        = string
}

variable "rate_limit_per_5min" {
  description = "Ek IP se 5 minutes mein max kitni requests allow hon /api/* pe"
  type        = number
  # Dev mein zyada rakho testing ke liye
  # Production mein kam rakho abuse rokne ke liye
  default     = 1000
}

variable "blocked_countries" {
  description = "Block karne wale country codes — empty list = koi block nahi"
  type        = list(string)
  default     = []
  # Example: ["KP", "IR", "CU"]
}

variable "admin_allowed_ips" {
  description = "Admin paths ke liye allowed IPs — CIDR format, empty = disabled"
  type        = list(string)
  default     = []
  # Example: ["203.0.113.0/32", "198.51.100.0/24"]
}
