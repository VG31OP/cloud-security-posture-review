# Cloud Security Posture Review & Remediation Project
## Automated Misconfiguration Assessment, Terraform Hardening, and Policy-as-Code Guardrails

[![CIS AWS Foundations Benchmark](https://img.shields.io/badge/CIS%20Benchmark-v3.0%20Compliant-success.svg)](https://www.cisecurity.org/)
[![Compliance Score](https://img.shields.io/badge/Compliance%20Score-94.55%25%20(+56.37%25)-brightgreen.svg)](#success-metrics)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform%20v1.5+-blue.svg)](https://www.terraform.io/)
[![Policy as Code](https://img.shields.io/badge/Policy%20as%20Code-Checkov%20%7C%20OPA-orange.svg)](#policy-as-code)

---

## 📌 Executive Overview
This repository contains the complete end-to-end deliverables for the **Cloud Security Engineer Internship (Pune Yuva Intern)**. 

### Scenario Context
A Pune-based environmental consulting enterprise (**GreenMetric ESG Analytics Ltd.**) migrated its digital infrastructure to AWS under tight market deadlines. The platform stores confidential corporate ESG disclosure drafts, proprietary sustainability scoring algorithms, and streaming IoT smart-meter telemetry data. An initial cloud posture audit revealed severe security oversights: unencrypted public storage buckets, administrative IAM accounts lacking MFA, direct internet exposure of database services, open SSH ports, and zero centralized audit logging.

This project executes a comprehensive posture turnaround:
1. **Audited & Benchmarked** the baseline infrastructure using **Prowler** and **ScoutSuite** against the **CIS AWS Foundations Benchmark v3.0**.
2. **Remediated All Critical & High Vulnerabilities** using modular, reproducible **Terraform Infrastructure as Code (IaC)**.
3. **Established Threat Detection & Real-Time Alerting** with **AWS CloudTrail**, **GuardDuty**, and **CloudWatch** metric filters for root activity and privilege escalation.
4. **Instituted Policy-as-Code Guardrails** with **Checkov** and **Open Policy Agent (OPA/Rego)** to prevent misconfiguration drift in CI/CD pipelines.
5. **Elevated CIS Compliance Score** from **38.18% to 94.55%** (+56.37% net improvement), surpassing the 40% improvement benchmark.

---

## 🏗️ Architecture & Remediation Matrix

```
                        [ Internet Traffic ]
                                 │
                                 ▼ (Denied Direct Public Access)
┌─────────────────────────────────────────────────────────────────────────────┐
│ AWS VPC (ap-south-1 Mumbai) [CIDR: 10.50.0.0/16]                            │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ Private Application Subnet (10.50.2.0/24)                           │   │
│   │   ┌─────────────────────────────────┐                               │   │
│   │   │ EC2 Workloads (SSM Managed)     │                               │   │
│   │   │ - No Public IP                  │                               │   │
│   │   │ - Ingress: Port 443 VPC Internal│                               │   │
│   │   │ - Egress: TLS Outbound Only     │                               │   │
│   │   └────────────────┬────────────────┘                               │   │
│   └────────────────────┼────────────────────────────────────────────────┘   │
│                        │ Port 5432 (Internal SG Reference Only)             │
│   ┌────────────────────▼────────────────────────────────────────────────┐   │
│   │ Private Database Subnet Group (10.50.3.0/24)                        │   │
│   │   ┌─────────────────────────────────┐                               │   │
│   │   │ RDS PostgreSQL (Multi-AZ)       │                               │   │
│   │   │ - publicly_accessible = false   │                               │   │
│   │   │ - storage_encrypted = KMS CMK   │                               │   │
│   │   │ - Automated 7-Day Backups       │                               │   │
│   │   └─────────────────────────────────┘                               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                 │
       ┌─────────────────────────┴─────────────────────────┐
       ▼                                                   ▼
┌───────────────────────────────┐           ┌───────────────────────────────┐
│ S3 Buckets (Encrypted & PAB)  │           │ Centralized Audit & SOC       │
│ - pune-esg-disclosure-drafts  │           │ - Multi-Region CloudTrail     │
│ - pune-esg-smartmeter-telemetry│          │ - Log File Validation Active  │
│ - Public Access Block: TRUE   │           │ - AWS GuardDuty Detector ON   │
│ - Customer KMS Key Encryption │           │ - CloudWatch Metric Alarms:   │
│ - Enforced TLS 1.2+ Transport │           │   * Root Login Alerts (CIS 3.3│
│ - Versioning: Enabled         │           │   * IAM Changes (CIS 3.4)     │
└───────────────────────────────┘           └───────────────────────────────┘
```

---

## 📊 Before vs. After Assessment Metrics

| Security Domain | Initial Baseline (Prowler) | Hardened State (IaC) | Status / Impact |
| :--- | :--- | :--- | :--- |
| **CIS Benchmark Compliance** | **38.18%** | **94.55%** | **+56.37% Score Boost** |
| **Critical Severity Defects** | 7 | **0** | **100% Remediated** |
| **High Severity Defects** | 18 | **0** | **100% Remediated** |
| **S3 Storage Security** | World readable; No encryption | KMS CMK + Public Block + TLS Enforce | Compliant (CIS 2.1) |
| **Database Security** | Publicly accessible; No encryption | Private Subnet + KMS + Multi-AZ | Compliant (CIS 2.3) |
| **Perimeter & Ingress** | SSH Port 22 open to `0.0.0.0/0` | Port 22 Closed; AWS SSM Only | Compliant (CIS 4.1) |
| **IAM Access Control** | Wildcard Admin; MFA Disabled | MFA Enforced; Least Privilege Roles | Compliant (CIS 1.16)|
| **Audit & Detection** | CloudTrail disabled; GuardDuty OFF | Multi-Region Trail + GuardDuty + SNS | Compliant (CIS 3.1) |

---

## 📂 Repository Structure

```
├── docs/
│   ├── INTERVIEW_VIVA_PREP.md             # AWS Shared Responsibility Model & Viva Defense
│   ├── Cloud_Security_Posture_Review_Report.docx # Official Submission Report (Word Doc)
│   └── architecture/                     # Architecture diagrams & schematics
├── policy-as-code/
│   ├── checkov/
│   │   └── .checkov.yml                  # Checkov CI/CD configuration & ruleset
│   └── opa/
│       ├── s3_restrict_public.rego       # OPA Rego rule preventing public S3 buckets
│       └── sg_restrict_ssh.rego          # OPA Rego rule blocking 0.0.0.0/0 SSH rules
├── scans/
│   ├── baseline-before/
│   │   ├── prowler_summary_before.json   # Machine-readable initial scan results
│   │   └── prowler_report_before.md      # Detailed baseline vulnerability report
│   └── hardened-after/
│       ├── prowler_summary_after.json    # Machine-readable post-remediation results
│       └── prowler_report_after.md       # Hardened compliance verification report
├── terraform/
│   ├── main.tf                           # Core orchestration provider & module calls
│   ├── variables.tf                      # Input parameter definitions
│   ├── outputs.tf                        # Resource outputs & compliance summary
│   ├── terraform.tfvars.example          # Sample environment variables
│   └── modules/
│       ├── iam/                          # Password policy, MFA enforcement, SSM roles
│       ├── s3/                           # S3 Public Block, KMS encryption, TLS policy
│       ├── network/                      # Hardened VPC, private subnets, security groups
│       ├── database/                     # Private RDS PostgreSQL, KMS encryption, Multi-AZ
│       └── monitoring/                   # CloudTrail, GuardDuty, CloudWatch alarms, SNS
└── README.md                             # Comprehensive project documentation
```

---

## 🚀 Deployment & Reproduction Instructions

### Prerequisites
- AWS CLI configured with valid credentials (`aws configure`)
- Terraform CLI v1.5+ installed
- Python 3.10+ (for report verification)

### Step 1: Initialize and Plan
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

### Step 2: Apply Hardened Architecture
```bash
terraform apply -auto-approve
```

### Step 3: Run Policy-as-Code Static Security Validation
```bash
# Checkov static analysis
checkov --config-file ../policy-as-code/checkov/.checkov.yml

# OPA Rego validation against Terraform plan
terraform show -json > tfplan.json
opa eval --data ../policy-as-code/opa/ --input tfplan.json "data.terraform.security"
```

---

## 📝 Submission Deliverables Checklist
- [x] **Word Document Report (`.docx`):** Generated in `docs/Cloud_Security_Posture_Review_Report.docx`.
- [x] **GitHub Repository URL:** Ready for push (`https://github.com/<username>/cloud-security-posture-review`).
- [x] **Project Description (200+ Words):** Detailed methodology, Pune ESG scenario, and technical metrics provided.
- [x] **Interview / Viva Preparedness:** AWS Shared Responsibility Model documentation in `docs/INTERVIEW_VIVA_PREP.md`.

---
**Author:** Vraj Shiroya  
**Role:** Cloud Security Engineer Intern  
**Program:** Yuva Intern Cloud Security Internship (Pune)
