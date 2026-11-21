terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ESG-Cloud-Security-Hardening"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "SecurityEngineeringTeam"
      Compliance  = "CIS-AWS-Foundations-v3.0"
    }
  }
}

# Network Security Module (VPC, Private Subnets, Hardened Security Groups)
module "network" {
  source              = "./modules/network"
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  environment         = var.environment
  admin_ingress_cidrs = var.admin_ingress_cidrs
}

# Identity and Access Management (Least-Privilege, MFA Enforcement, Password Policy)
module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}

# Secure Storage Module (S3 Bucket Hardening: Public Access Block, KMS SSE, TLS Enforcement)
module "s3_storage" {
  source             = "./modules/s3"
  bucket_name_prefix = var.bucket_name_prefix
  environment        = var.environment
  log_bucket_id      = module.s3_storage.access_logs_bucket_id
}

# Secure Relational Database Module (RDS PostgreSQL, KMS Encrypted, Private Subnet, Multi-AZ)
module "database" {
  source              = "./modules/database"
  environment         = var.environment
  vpc_id              = module.network.vpc_id
  database_subnet_ids = module.network.private_subnet_ids
  app_security_group_id = module.network.app_security_group_id
  db_name             = var.db_name
  db_username         = var.db_username
}

# Detection, Threat Intelligence & Logging Module (CloudTrail, GuardDuty, CloudWatch Alarms)
module "monitoring" {
  source             = "./modules/monitoring"
  environment        = var.environment
  alert_email_address = var.alert_email_address
  cloudtrail_bucket_id = module.s3_storage.cloudtrail_bucket_id
}
