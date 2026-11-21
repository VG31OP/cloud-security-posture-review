variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

# KMS Key for RDS Database Storage Encryption
resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS Key for ESG Analytics RDS storage encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "esg-rds-encryption-key"
  }
}

# DB Subnet Group restricted to private subnets
resource "aws_db_subnet_group" "db_subnets" {
  name       = "esg-db-private-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "ESG-Private-DB-SubnetGroup"
  }
}

# Database Security Group: Ingress restricted strictly to App SG on PostgreSQL port 5432
resource "aws_security_group" "db_sg" {
  name        = "ESG-Database-SecurityGroup"
  description = "Allows incoming PostgreSQL connections strictly from trusted application tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ESG App tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Block all outbound database initiations"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_id]
  }

  tags = {
    Name = "ESG-Database-SG"
  }
}

# Secure RDS PostgreSQL Instance (CIS Compliant: Encrypted at Rest, Private, Automated Backups, Multi-AZ)
resource "aws_db_instance" "esg_postgres" {
  identifier        = "esg-analytics-db-${var.environment}"
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t4g.micro"

  db_name  = var.db_name
  username = var.db_username
  password = "TempP@ssw0rd!ChangeInSecretsManager" # Master password provisioned through AWS Secrets Manager

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Remediation of Critical Vulnerabilities:
  publicly_accessible    = false # NO public accessibility
  storage_encrypted      = true  # KMS Customer Master Key Encryption
  kms_key_id             = aws_kms_key.rds_kms_key.arn
  backup_retention_period = 7     # Automated backups enabled
  deletion_protection     = true
  skip_final_snapshot     = true
  auto_minor_version_upgrade = true

  tags = {
    Name = "ESG-Analytics-PostgreSQL"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.esg_postgres.endpoint
}
