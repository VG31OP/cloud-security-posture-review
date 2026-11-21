package terraform.security.s3

# Rule: Deny S3 buckets without explicit Public Access Block enabled
default allow = false

# Allow if all 4 public access block flags are set to true
allow {
    resource := input.resource.aws_s3_bucket_public_access_block[_]
    resource.block_public_acls == true
    resource.block_public_policy == true
    resource.ignore_public_acls == true
    resource.restrict_public_buckets == true
}

# Generate violation messages for pull requests and CI/CD pipelines
deny[msg] {
    bucket := input.resource.aws_s3_bucket[name]
    not has_public_access_block(name)
    msg := sprintf("CRITICAL POLICY VIOLATION: S3 Bucket '%v' must have aws_s3_bucket_public_access_block configured with all public access restrictions enabled.", [name])
}

has_public_access_block(bucket_name) {
    pab := input.resource.aws_s3_bucket_public_access_block[_]
    pab.bucket == sprintf("${aws_s3_bucket.%v.id}", [bucket_name])
}

deny[msg] {
    bucket := input.resource.aws_s3_bucket[name]
    not has_encryption_configured(name)
    msg := sprintf("HIGH POLICY VIOLATION: S3 Bucket '%v' is missing server-side encryption configuration (KMS or AES256).", [name])
}

has_encryption_configured(bucket_name) {
    enc := input.resource.aws_s3_bucket_server_side_encryption_configuration[_]
    enc.bucket == sprintf("${aws_s3_bucket.%v.id}", [bucket_name])
}
