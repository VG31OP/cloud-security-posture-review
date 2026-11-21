variable "bucket_name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_bucket_id" {
  type    = string
  default = ""
}

# KMS Key for S3 Customer-Managed Encryption
resource "aws_kms_key" "s3_kms_key" {
  description             = "KMS Customer Master Key for encrypting ESG disclosure documents & smart-meter data"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "esg-s3-encryption-key"
  }
}

# S3 Access Logging Bucket
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.bucket_name_prefix}-access-logs-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail Dedicated Log Bucket
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.bucket_name_prefix}-cloudtrail-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ESG Disclosure Drafts Bucket (High Sensitivity)
resource "aws_s3_bucket" "disclosure_drafts" {
  bucket        = "${var.bucket_name_prefix}-disclosure-drafts-${var.environment}"
  force_destroy = true
}

# CIS Control 2.1.5: Enforce S3 Block Public Access
resource "aws_s3_bucket_public_access_block" "disclosure_drafts" {
  bucket = aws_s3_bucket.disclosure_drafts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS Control 2.1.1: S3 Bucket Encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "disclosure_drafts" {
  bucket = aws_s3_bucket.disclosure_drafts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 Versioning (Data Integrity & Ransomware Protection)
resource "aws_s3_bucket_versioning" "disclosure_drafts" {
  bucket = aws_s3_bucket.disclosure_drafts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce In-Transit TLS 1.2+ HTTPS Only
resource "aws_s3_bucket_policy" "disclosure_drafts_ssl_only" {
  bucket = aws_s3_bucket.disclosure_drafts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.disclosure_drafts.arn,
          "${aws_s3_bucket.disclosure_drafts.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Smart-Meter Telemetry Bucket (IoT Streaming Data)
resource "aws_s3_bucket" "smartmeter_telemetry" {
  bucket        = "${var.bucket_name_prefix}-smartmeter-telemetry-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "smartmeter_telemetry" {
  bucket = aws_s3_bucket.smartmeter_telemetry.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "smartmeter_telemetry" {
  bucket = aws_s3_bucket.smartmeter_telemetry.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "smartmeter_telemetry" {
  bucket = aws_s3_bucket.smartmeter_telemetry.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "disclosure_bucket_arn" {
  value = aws_s3_bucket.disclosure_drafts.arn
}

output "telemetry_bucket_arn" {
  value = aws_s3_bucket.smartmeter_telemetry.arn
}

output "access_logs_bucket_id" {
  value = aws_s3_bucket.access_logs.id
}

output "cloudtrail_bucket_id" {
  value = aws_s3_bucket.cloudtrail_logs.id
}
