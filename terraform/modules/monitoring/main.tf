variable "environment" {
  type = string
}

variable "alert_email_address" {
  type = string
}

variable "cloudtrail_bucket_id" {
  type = string
}

# KMS Key for CloudTrail Encryption
resource "aws_kms_key" "cloudtrail_key" {
  description             = "KMS Key for multi-region CloudTrail log encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# SNS Alert Topic for Security Operations Center (SOC)
resource "aws_sns_topic" "security_alerts" {
  name = "esg-security-incident-alerts"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
}

# CloudWatch Log Group for Centralized Audit Ingestion
resource "aws_cloudwatch_log_group" "cloudtrail_audit_logs" {
  name              = "/aws/cloudtrail/esg-central-audit-log"
  retention_in_days = 180
}

# IAM Role for CloudTrail to publish events to CloudWatch
resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "ESG-CloudTrail-CloudWatch-Delivery-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "ESG-CloudTrail-CW-PutEvents"
  role = aws_iam_role.cloudtrail_cw_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.cloudtrail_audit_logs.arn}:*"
      }
    ]
  })
}

# Multi-Region CloudTrail Trail (CIS Controls 2.1 - 2.7)
resource "aws_cloudtrail" "main_audit_trail" {
  name                          = "esg-production-audit-trail"
  s3_bucket_name                = var.cloudtrail_bucket_id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true # CIS 2.2: Cryptographic digest validation
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_audit_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw_role.arn

  tags = {
    Name = "ESG-Audit-Trail"
  }
}

# AWS GuardDuty Threat Detection (CIS Benchmark 2.8)
resource "aws_guardduty_detector" "primary" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name = "ESG-GuardDuty-Detector"
  }
}

# --- CloudWatch Metric Filters & Alarms for CIS AWS Foundations Benchmark ---

# CIS 3.1: Metric Filter & Alarm for Unauthorized API Calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "UnauthorizedAPICalls"
  pattern        = "{($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\")}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_audit_logs.name

  metric_transformation {
    name      = "UnauthorizedAPICallsCount"
    namespace = "CloudTrailSecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls_alarm" {
  alarm_name          = "CIS-3.1-Unauthorized-API-Calls-Detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICallsCount"
  namespace           = "CloudTrailSecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Triggers whenever unauthorized API operations or Access Denied responses are detected."
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

# CIS 3.3: Metric Filter & Alarm for Root Account Usage
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "RootAccountUsage"
  pattern        = "{$.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\"}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_audit_logs.name

  metric_transformation {
    name      = "RootAccountUsageCount"
    namespace = "CloudTrailSecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_account_usage_alarm" {
  alarm_name          = "CIS-3.3-Root-Account-Usage-Detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountUsageCount"
  namespace           = "CloudTrailSecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Critical: Alerts immediately whenever the AWS root account credentials are used."
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

# CIS 3.4: Metric Filter & Alarm for IAM Policy Changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "IAMPolicyChanges"
  pattern        = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_audit_logs.name

  metric_transformation {
    name      = "IAMPolicyChangesCount"
    namespace = "CloudTrailSecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "CIS-3.4-IAM-Policy-Changes-Detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChangesCount"
  namespace           = "CloudTrailSecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alerts when administrative modifications or privilege escalations occur on IAM policies."
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

# CIS 3.10: Metric Filter & Alarm for Security Group Changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "SecurityGroupChanges"
  pattern        = "{($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup)}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_audit_logs.name

  metric_transformation {
    name      = "SecurityGroupChangesCount"
    namespace = "CloudTrailSecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes_alarm" {
  alarm_name          = "CIS-3.10-Security-Group-Changes-Detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChangesCount"
  namespace           = "CloudTrailSecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alerts whenever security groups are created, updated, or ingress/egress rules are altered."
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

output "trail_arn" {
  value = aws_cloudtrail.main_audit_trail.arn
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.primary.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.security_alerts.arn
}
