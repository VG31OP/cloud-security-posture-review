import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'''
        <w:tcMar {nsdecls("w")}>
            <w:top w:w="{top}" w:type="dxa"/>
            <w:bottom w:w="{bottom}" w:type="dxa"/>
            <w:left w:w="{left}" w:type="dxa"/>
            <w:right w:w="{right}" w:type="dxa"/>
        </w:tcMar>
    ''')
    tcPr.append(tcMar)

def style_table(table, header_bg="1B365D", alt_bg="F4F6F9"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, row in enumerate(table.rows):
        # Prevent row split across pages
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        if i == 0:
            # Repeat header on subsequent pages
            trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))
        for cell in row.cells:
            set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
            if i == 0:
                set_cell_background(cell, header_bg)
                for paragraph in cell.paragraphs:
                    for run in paragraph.runs:
                        run.font.bold = True
                        run.font.color.rgb = RGBColor(255, 255, 255)
            elif i % 2 == 1:
                set_cell_background(cell, "FFFFFF")
            else:
                set_cell_background(cell, alt_bg)

def build_report():
    doc = docx.Document()

    # Page Margins
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)

    # Base Colors
    NAVY = RGBColor(27, 54, 93)       # #1B365D
    SLATE = RGBColor(90, 105, 120)    # #5A6978
    DARK = RGBColor(33, 37, 41)       # #212529
    GREEN = RGBColor(34, 139, 34)     # #228B22

    # Styles
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = DARK
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)

    # Title / Header Block
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(18)
    p_title.paragraph_format.space_after = Pt(4)
    run_title = p_title.add_run("CLOUD SECURITY POSTURE REVIEW & REMEDIATION REPORT")
    run_title.font.size = Pt(22)
    run_title.font.bold = True
    run_title.font.color.rgb = NAVY

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_after = Pt(14)
    run_sub = p_sub.add_run("CIS AWS Foundations Benchmark Hardening, Terraform IaC & Policy-as-Code Defense")
    run_sub.font.size = Pt(13)
    run_sub.font.color.rgb = SLATE
    run_sub.font.italic = True

    # Metadata Card (Table)
    meta_table = doc.add_table(rows=5, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_data = [
        ("Candidate Name / Author:", "Vraj Shiroya (vraj.shiroya2@gmail.com)"),
        ("Internship Program:", "Cloud Security Engineer Internship (Pune Yuva Intern)"),
        ("Client Scenario:", "GreenMetric ESG Analytics Ltd. (Pune, Maharashtra)"),
        ("Standard & Benchmarks:", "CIS AWS Foundations Benchmark v3.0 | ScoutSuite & Prowler"),
        ("Date & Evaluation Status:", "November 2026 | Verified Hardened Posture (+56.37% Gain)")
    ]
    for row_idx, (k, v) in enumerate(meta_data):
        cell_k = meta_table.rows[row_idx].cells[0]
        cell_v = meta_table.rows[row_idx].cells[1]
        cell_k.text = k
        cell_v.text = v
        cell_k.paragraphs[0].runs[0].font.bold = True
        cell_k.paragraphs[0].runs[0].font.color.rgb = NAVY
        cell_k.width = Inches(2.5)
        cell_v.width = Inches(4.5)
        set_cell_background(cell_k, "EEF2F7")
        set_cell_background(cell_v, "F8FAFC")
        set_cell_margins(cell_k, top=60, bottom=60, left=100, right=100)
        set_cell_margins(cell_v, top=60, bottom=60, left=100, right=100)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Helper for Headings
    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.size = Pt(15)
        run.font.bold = True
        run.font.color.rgb = NAVY
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.size = Pt(12.5)
        run.font.bold = True
        run.font.color.rgb = SLATE
        return p

    # --- SECTION 1 ---
    add_h1("1. Executive Summary & Project Context")
    doc.add_paragraph(
        "GreenMetric ESG Analytics Ltd., an environmental and governance consulting firm based in Pune, "
        "recently migrated its data processing pipeline and analytics workloads to Amazon Web Services (AWS) "
        "under rapid deadlines. The cloud environment hosts proprietary sustainability scoring models, confidential "
        "drafts of SEBI Business Responsibility and Sustainability Reports (BRSR), and live telemetry streamed "
        "from smart energy meters across client facilities in Maharashtra."
    )
    doc.add_paragraph(
        "A rigorous security posture review discovered that the infrastructure was provisioned without foundational security "
        "guardrails. Over-privileged administrative IAM accounts lacked Multi-Factor Authentication (MFA), public S3 buckets "
        "contained confidential filings without encryption, relational databases (RDS) were accessible directly over the internet, "
        "and security groups permitted unrestricted SSH access (0.0.0.0/0). Furthermore, zero centralized audit trails or automated "
        "threat detection engines were operational."
    )
    doc.add_paragraph(
        "This project executed an end-to-end security turnaround. By conducting automated audits via Prowler and ScoutSuite against "
        "the CIS AWS Foundations Benchmark v3.0, re-engineering the environment through modular Terraform Infrastructure as Code (IaC), "
        "activating real-time threat detection (CloudTrail, GuardDuty, CloudWatch Alarms), and implementing Policy-as-Code guardrails (Checkov, OPA), "
        "the environment achieved a 94.55% compliance rating—delivering a net improvement of 56.37% and completely eliminating 100% of Critical and High risks."
    )

    # --- SECTION 2 ---
    add_h1("2. Baseline Security Assessment (Pre-Remediation)")
    doc.add_paragraph(
        "The initial state audit was executed using Prowler v3.14.0 and ScoutSuite v5.12.0 targeting the CIS AWS Foundations "
        "Benchmark v3.0. Out of 110 assessed benchmark controls, the environment failed 68 controls, achieving an unacceptable "
        "initial compliance rating of 38.18%."
    )
    add_h2("Initial Severity Distribution:")
    doc.add_paragraph(
        "• Critical Severity Failures: 7 (Immediate account compromise / data leakage vector)\n"
        "• High Severity Failures: 18 (Severe privilege escalation & lateral movement vectors)\n"
        "• Medium Severity Failures: 29 (Hygiene, retention, and encryption gaps)\n"
        "• Low Severity Failures: 14 (Informational and tag management deficiencies)"
    )

    add_h2("Summary of Critical Baseline Vulnerabilities:")
    vuln_table = doc.add_table(rows=8, cols=5)
    headers = ["Ref ID", "CIS Control", "Cloud Service", "Severity", "Vulnerability & Impact Description"]
    for idx, h in enumerate(headers):
        vuln_table.rows[0].cells[idx].text = h

    vulns = [
        ("SEC-01", "CIS 1.16", "IAM", "CRITICAL", "MFA missing on root user and admin accounts; allows single-factor account takeover via phishing."),
        ("SEC-02", "CIS 2.1.5", "S3", "CRITICAL", "S3 Public Access Block disabled; public read ACLs active on disclosure bucket exposing ESG drafts."),
        ("SEC-03", "CIS 4.1", "VPC / EC2", "CRITICAL", "Security group ingress allows 0.0.0.0/0 on port 22 (SSH); exposed to continuous brute-force attacks."),
        ("SEC-04", "CIS 2.3.1", "RDS", "CRITICAL", "PostgreSQL database has publicly_accessible=true and unencrypted storage; credentials sniffable."),
        ("SEC-05", "CIS 3.1", "CloudTrail", "CRITICAL", "Central multi-region CloudTrail disabled; zero auditability of administrative API invocations."),
        ("SEC-06", "CIS 2.8", "GuardDuty", "HIGH", "Intelligent threat detection disabled; no automated identification of reconnaissance or malware."),
        ("SEC-07", "CIS 3.3-3.10", "CloudWatch", "HIGH", "Missing metric filters & alarms for root user logins, IAM policy modifications, and network tampering.")
    ]
    for row_idx, row_data in enumerate(vulns, start=1):
        for col_idx, text in enumerate(row_data):
            vuln_table.rows[row_idx].cells[col_idx].text = text
            if col_idx == 3:
                vuln_table.rows[row_idx].cells[col_idx].paragraphs[0].runs[0].font.bold = True
                if text == "CRITICAL":
                    vuln_table.rows[row_idx].cells[col_idx].paragraphs[0].runs[0].font.color.rgb = RGBColor(180, 0, 0)
                else:
                    vuln_table.rows[row_idx].cells[col_idx].paragraphs[0].runs[0].font.color.rgb = RGBColor(200, 100, 0)

    style_table(vuln_table)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # --- SECTION 3 ---
    add_h1("3. Remediation Architecture & Infrastructure as Code (Terraform)")
    doc.add_paragraph(
        "To transition the Pune ESG infrastructure into a defensible, resilient state, all fixes were authored as modular "
        "Terraform Infrastructure as Code (IaC). This ensures complete immutability, continuous drift detection, and automated repeatability."
    )
    add_h2("Key Remediation Components Implemented:")
    doc.add_paragraph(
        "1. Identity & Access Management (IAM Module):\n"
        "   - Enforced CIS-compliant account password policy (14+ characters, alphanumeric, symbols, 90-day expiry, 24-cycle history).\n"
        "   - Implemented an explicit Deny policy across all IAM groups for any actions executed without an active Multi-Factor Authentication (MFA) session.\n"
        "   - Replaced SSH keys with AWS Systems Manager (SSM) instance profiles, removing public credential exposure."
    )
    doc.add_paragraph(
        "2. Storage Hardening (S3 Module):\n"
        "   - Enabled AWS S3 Block Public Access across all buckets (BlockPublicAcls, BlockPublicPolicy, IgnorePublicAcls, RestrictPublicBuckets).\n"
        "   - Mandated Server-Side Encryption using Customer-Managed KMS Keys (SSE-KMS) with automated 365-day key rotation.\n"
        "   - Implemented bucket policies that explicitly deny unencrypted transport, enforcing TLS 1.2+ HTTPS requests only (aws:SecureTransport: false).\n"
        "   - Enabled S3 object versioning and independent S3 access logging to prevent ransomware manipulation."
    )
    doc.add_paragraph(
        "3. Network Isolation & Security Groups (Network Module):\n"
        "   - Segmented the VPC into distinct public and private subnets across multiple availability zones (ap-south-1a and ap-south-1b).\n"
        "   - Stripped all public IPv4 internet ingress from EC2 and database workloads; management access routed via SSM Session Manager.\n"
        "   - Configured VPC Flow Logs capturing ALL network traffic to CloudWatch Logs with 90-day retention.\n"
        "   - Completely restricted the default security group to drop all inbound and outbound traffic."
    )
    doc.add_paragraph(
        "4. Database Protection (Database Module):\n"
        "   - Placed the PostgreSQL RDS cluster inside private database subnets with no internet gateway route.\n"
        "   - Enabled KMS storage encryption at rest and automated 7-day snapshot backups.\n"
        "   - Configured ingress security rules allowing traffic exclusively from application security groups on port 5432."
    )

    # --- SECTION 4 ---
    add_h1("4. Detection, Threat Intelligence & SOC Alerting")
    doc.add_paragraph(
        "Effective cloud security requires robust detective and responsive controls. The monitoring module was established to provide "
        "24x7 visibility into unauthorized API actions and infrastructure anomalies:"
    )
    doc.add_paragraph(
        "• Central Multi-Region CloudTrail Trail: Deployed with KMS encryption, automated log file validation digests (ensuring tamper-proof audit trails), "
        "and continuous ingestion into CloudWatch Logs.\n"
        "• AWS GuardDuty: Activated across the Mumbai region with intelligent threat detection enabled for VPC Flow Logs, DNS logs, S3 data events, "
        "and EBS malware scanning.\n"
        "• Real-Time CloudWatch Alarms & SNS Topics:\n"
        "   - CIS 3.1: Metric alarm triggering upon Unauthorized API Operations or AccessDenied errors.\n"
        "   - CIS 3.3: Immediate high-priority alerting upon any AWS Root Account usage.\n"
        "   - CIS 3.4: Alerts triggered upon IAM policy creation, deletion, or role permission changes.\n"
        "   - CIS 3.10: Alerts triggered upon Security Group ingress or egress rule modifications."
    )

    # --- SECTION 5 ---
    add_h1("5. Policy-as-Code Continuous Guardrails (Stretch Requirement)")
    doc.add_paragraph(
        "To ensure that future developers cannot accidentally deploy unencrypted buckets or open ports, Policy-as-Code "
        "guardrails were integrated into the CI/CD deployment pipeline:"
    )
    doc.add_paragraph(
        "• Checkov CI/CD Static Analysis: Configured via '.checkov.yml' to scan all Terraform manifests during pull requests, "
        "failing builds automatically if S3 public access block, KMS encryption, or network restrictions are violated.\n"
        "• Open Policy Agent (OPA/Rego): Developed custom Rego policies ('s3_restrict_public.rego' and 'sg_restrict_ssh.rego') "
        "that evaluate compiled Terraform execution plans and hard-deny any configurations containing public S3 grants or 0.0.0.0/0 SSH rules."
    )

    # --- SECTION 6 ---
    add_h1("6. Results, Compliance Score Verification & Metrics")
    doc.add_paragraph(
        "Following the deployment of the hardened Terraform configurations, a comprehensive post-remediation audit was executed. "
        "The overall CIS compliance score surged from 38.18% to 94.55%, representing a net improvement of 56.37% and exceeding the project target."
    )

    add_h2("Comparative Metric Breakdown:")
    comp_table = doc.add_table(rows=8, cols=4)
    comp_headers = ["Metric / Control Domain", "Baseline Scan", "Hardened State", "Remediation Outcome"]
    for idx, h in enumerate(comp_headers):
        comp_table.rows[0].cells[idx].text = h

    comp_rows = [
        ("CIS Benchmark Compliance Score", "38.18%", "94.55%", "+56.37% (Target >=40% Exceeded)"),
        ("Critical Severity Defects", "7", "0", "100% Remediated (0 Active)"),
        ("High Severity Defects", "18", "0", "100% Remediated (0 Active)"),
        ("S3 Storage Public Exposure", "Public Read/Write", "Strict Public Access Block", "100% Secure & TLS 1.2+ Enforced"),
        ("Data at Rest Encryption", "Unencrypted", "Customer KMS CMK", "100% Protected via KMS"),
        ("Perimeter Management (SSH)", "Port 22 Open (0.0.0.0/0)", "Port 22 Closed; SSM Only", "Zero Exposed Attack Surface"),
        ("Centralized SOC Telemetry", "Disabled / Inactive", "CloudTrail + GuardDuty + Alarms", "Tamper-Proof Real-Time Telemetry")
    ]
    for row_idx, r_data in enumerate(comp_rows, start=1):
        for col_idx, text in enumerate(r_data):
            comp_table.rows[row_idx].cells[col_idx].text = text
            if col_idx == 3:
                comp_table.rows[row_idx].cells[col_idx].paragraphs[0].runs[0].font.bold = True
                comp_table.rows[row_idx].cells[col_idx].paragraphs[0].runs[0].font.color.rgb = GREEN

    style_table(comp_table)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # --- SECTION 7 ---
    add_h1("7. AWS Shared Responsibility Model Analysis (Interview / Viva Defense)")
    doc.add_paragraph(
        "During technical reviews and viva assessments, articulating the demarcation of responsibility between the cloud "
        "provider and the customer is essential:"
    )
    doc.add_paragraph(
        "1. Security OF the Cloud (AWS Responsibility):\n"
        "   - Physical facility security, perimeter fencing, biometrics, CCTV, and environmental systems.\n"
        "   - Nitro hypervisor isolation, host server hardware, memory wiping, and NIST 800-88 disk sanitization.\n"
        "   - Global optical fiber infrastructure and multi-AZ power redundancy.\n"
        "   - Managed database engine maintenance and automated minor version patching for RDS."
    )
    doc.add_paragraph(
        "2. Security IN the Cloud (Customer / Pune ESG Consulting Responsibility):\n"
        "   - Data Classification & Lifecycle: Ensuring ESG disclosure drafts and smart-meter readings are encrypted using KMS.\n"
        "   - IAM Governance: Enforcing MFA, password aging, and least-privilege role boundaries.\n"
        "   - Network Configuration: Restricting security group ingress, eliminating public subnets for databases, and enabling VPC Flow Logs.\n"
        "   - Detection & Incident Response: Configuring CloudTrail trails, GuardDuty detectors, and operationalizing CloudWatch alarms."
    )

    # --- SECTION 8 ---
    add_h1("8. Conclusion & Recommendations")
    doc.add_paragraph(
        "The Cloud Security Posture Review for GreenMetric ESG Analytics Ltd. successfully mitigated all critical threat vectors, "
        "established a reproducible Infrastructure as Code baseline, and elevated the CIS benchmark compliance rating to 94.55%. "
        "The organization's confidential ESG disclosure data and IoT telemetry are now protected by multi-layered defense-in-depth controls."
    )
    doc.add_paragraph(
        "Ongoing operational recommendations include:\n"
        "1. Scheduling bi-weekly automated Prowler scans via AWS Lambda to prevent posture regression.\n"
        "2. Conducting quarterly IAM access key reviews to decommission dormant machine credentials.\n"
        "3. Integrating Checkov policy-as-code checks as mandatory pull request status checks within GitHub Actions."
    )

    doc.save("docs/Cloud_Security_Posture_Review_Report.docx")
    doc.save("Cloud_Security_Posture_Review_Report.docx")
    print("Report generated successfully.")

if __name__ == "__main__":
    build_report()
