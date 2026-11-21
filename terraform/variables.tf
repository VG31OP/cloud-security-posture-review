variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1" # Mumbai region (closest to Pune enterprise hub)
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.50.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ resiliency"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "admin_ingress_cidrs" {
  description = "Trusted administrative IP addresses for jump-host / bastion access"
  type        = list(string)
  default     = ["103.21.124.0/24"] # Example corporate HQ IP range
}

variable "bucket_name_prefix" {
  description = "Prefix for ESG disclosure and telemetry storage buckets"
  type        = string
  default     = "pune-esg-data"
}

variable "db_name" {
  description = "Name of the ESG analytics relational database"
  type        = string
  default     = "esg_analytics_db"
}

variable "db_username" {
  description = "Master username for RDS PostgreSQL instance"
  type        = string
  default     = "esg_admin_sec"
}

variable "alert_email_address" {
  description = "Email address for receiving high-priority security notifications and CIS alerts"
  type        = string
  default     = "security-ops@puneesg-consulting.local"
}
