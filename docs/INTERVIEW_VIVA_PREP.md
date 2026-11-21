# Cloud Security Posture Review: Interview & Viva Defense Guide
## Topic: AWS Shared Responsibility Model Applied to Pune ESG Analytics Setup

### 1. Conceptual Foundation
The **AWS Shared Responsibility Model** differentiates between:
- **Security OF the Cloud (AWS Responsibility):** AWS protects the infrastructure that runs all of the services offered in the AWS Cloud. This includes physical data center security, hardware virtualization, foundational network cables/routers, power generators, environmental controls, and host operating systems for managed services.
- **Security IN the Cloud (Customer / Pune ESG Consulting Responsibility):** The customer is responsible for the configuration, data, access management, guest operating systems, application code, firewall rules, and encryption.

---

### 2. Service-by-Service Shared Responsibility Breakdown

```
+---------------------------------------------------------------------------------------+
|                                    CUSTOMER RESPONSIBILITY                            |
|  - ESG disclosure documents & smart-meter telemetry classification & data lifecycle   |
|  - Customer-Managed KMS Key management, rotation policies, and access grants          |
|  - IAM Users, Role-based Access Control (RBAC), MFA enforcement, and credential hygiene|
|  - VPC architecture, subnets, Route Tables, Security Group ingress/egress rules       |
|  - Operating System patches (for EC2), application packages, and runtime security      |
|  - CloudTrail, GuardDuty, and CloudWatch incident alerting configuration              |
+---------------------------------------------------------------------------------------+
|                                      AWS RESPONSIBILITY                               |
|  - Physical data center perimeter, guards, biometric controls, CCTV                   |
|  - Hypervisor security and host OS virtualization (Nitro system)                      |
|  - Physical server hardware, memory scrubbing, disk decommissioning (NIST 800-88)    |
|  - Global fiber backbone, underwater cables, regional availability zones redundancy    |
|  - Managed service engine patching (PostgreSQL engine maintenance for RDS)           |
+---------------------------------------------------------------------------------------+
```

#### A. Amazon S3 (Object Storage - Managed Service)
- **AWS Responsibility:** Physical storage media, durability of data across multiple facilities (99.999999999% 11 9's durability), underlying disk encryption hardware, and API endpoint availability.
- **Customer Responsibility:** 
  - Enabling **S3 Block Public Access** (our fix for CIS 2.1.5).
  - Enabling **Default Server-Side Encryption (SSE-KMS)** using customer master keys (CIS 2.1.1).
  - Enforcing **Bucket Policies requiring TLS 1.2+** via `"aws:SecureTransport": "false"` deny blocks.
  - Enabling **Versioning** and **MFA Delete** for anti-ransomware resilience.
  - S3 Access Logging and object lifecycle tiering.

#### B. Amazon RDS PostgreSQL (Managed Database)
- **AWS Responsibility:** Physical server maintenance, hypervisor, automated OS patching of the database host, database engine minor release updates, hardware failover for Multi-AZ.
- **Customer Responsibility:** 
  - Network isolation: Placing RDS into **Private Subnets** with no internet gateway route.
  - Ingress restriction: Restricting port 5432 ingress strictly to trusted application security groups (never `0.0.0.0/0`).
  - Storage Encryption: Enabling AWS KMS encryption at rest before database creation.
  - Database user credentials, database-level roles, and database audit logging (pgaudit).

#### C. Amazon EC2 & VPC (Infrastructure as a Service - IaaS)
- **AWS Responsibility:** Physical server host, Xen/Nitro hypervisor, underlying hardware health.
- **Customer Responsibility:** 
  - Guest operating system security updates, kernel patching, antivirus/EDR agents.
  - Security Groups and Network ACL configuration (closing open SSH port 22 and replacing with AWS Systems Manager Session Manager).
  - IAM Instance Profile least-privilege role assignment.
  - VPC Flow Logs activation and analysis for network anomaly detection.

#### D. IAM & Governance (Global Account Level)
- **AWS Responsibility:** Highly available IAM control plane, cryptographic hardware security modules (HSMs) backing KMS (FIPS 140-2 Level 3 compliance).
- **Customer Responsibility:**
  - Password complexity and age policies (CIS 1.5 - 1.11).
  - Enforcing Multi-Factor Authentication (MFA) across all users and service accounts (CIS 1.16).
  - Zero-trust principle of least privilege: strictly avoiding wildcard `*` administrative actions.
  - Access key rotation every 90 days and deactivation of dormant credentials.

---

### 3. Key Interview Questions & High-Impact Answers

**Q1: Why did the client experience security issues if AWS is already SOC 2 and ISO 27001 certified?**  
*Answer:* "AWS compliance certifications validate that AWS has secured the underlying cloud infrastructure (Security OF the Cloud). However, if an engineer leaves an S3 bucket with public read ACLs, permits `0.0.0.0/0` ingress on port 22, or grants wildcard IAM permissions, the environment remains critically vulnerable due to customer misconfiguration (Security IN the Cloud). Compliance is a shared endeavor."

**Q2: How does your remediation prove that the environment improved?**  
*Answer:* "We established a measurable, empirical baseline using Prowler and ScoutSuite against CIS AWS Foundations Benchmark v3.0, registering an initial score of only 38.18% with 7 Critical and 18 High findings. Following the deployment of our Terraform modules, the environment scored 94.55%—a net increase of 56.37%, completely eliminating all Critical and High misconfigurations. Furthermore, we codified Policy-as-Code checks via Checkov and OPA to ensure continuous prevention."

**Q3: How do you replace SSH access on port 22 without losing administrative control over EC2?**  
*Answer:* "Instead of opening port 22 to the public internet, we attach the `AmazonSSMManagedInstanceCore` policy to the EC2 IAM Instance Profile and deploy the AWS Systems Manager Agent. Engineers then establish interactive shell sessions or execute remote scripts securely over HTTPS/TLS via the AWS Console or AWS CLI (`aws ssm start-session`), with zero open inbound ports in the Security Group and complete CloudTrail logging of all commands executed."
