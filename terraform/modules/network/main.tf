variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "admin_ingress_cidrs" {
  type = list(string)
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ESG-VPC-${var.environment}"
  }
}

# CIS Control 3.9: VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs_group" {
  name              = "/aws/vpc/flowlogs-esg-${var.environment}"
  retention_in_days = 90
}

resource "aws_iam_role" "flow_logs_role" {
  name = "ESG-VPC-FlowLogs-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "ESG-VPC-FlowLogs-Delivery"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow" {
  iam_role_arn    = aws_iam_role.flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# Subnets: Two Private Subnets for App and DB workloads, Isolated from Public Internet
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "ESG-Private-Subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# Public Subnet for NAT / Ingress Gateways
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false # No automated public IP assignment

  tags = {
    Name = "ESG-Public-Subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# Hardened Security Group (CIS Benchmark 4.1 & 4.2: Disallow 0.0.0.0/0 on Port 22 and 3389)
resource "aws_security_group" "app_sg" {
  name        = "ESG-Application-SecurityGroup"
  description = "Hardened security group for ESG workloads with strict ingress rules"
  vpc_id      = aws_vpc.main.id

  # Ingress restricted to internal VPC or authorized admin range (NO 0.0.0.0/0 SSH)
  ingress {
    description = "HTTPS internal traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow HTTPS outbound for API / OS patching"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ESG-App-SG"
  }
}

# Default Security Group Hardened (CIS Benchmark 4.3: Restrict all traffic on default SG)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules defined -> completely blocks default SG abuse
  tags = {
    Name = "ESG-Default-SG-Closed"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "app_security_group_id" {
  value = aws_security_group.app_sg.id
}
