package terraform.security.network

# Rule: Deny any Security Group ingress rule allowing 0.0.0.0/0 on sensitive administrative ports (22, 3389, 5432, 3306)

deny[msg] {
    sg := input.resource.aws_security_group[name]
    rule := sg.ingress[_]
    cidr := rule.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    is_sensitive_port(rule.from_port, rule.to_port)
    msg := sprintf("CRITICAL NETWORK POLICY VIOLATION: Security group '%v' allows unrestricted ingress (0.0.0.0/0) on sensitive port range %v-%v.", [name, rule.from_port, rule.to_port])
}

is_sensitive_port(from_p, to_p) {
    from_p <= 22
    to_p >= 22
}

is_sensitive_port(from_p, to_p) {
    from_p <= 3389
    to_p >= 3389
}

is_sensitive_port(from_p, to_p) {
    from_p <= 5432
    to_p >= 5432
}
