# ── De-identified EHR Data Bucket ─────────────────────────────────────────
# Stores de-identified patient records. The account ID suffix guarantees a
# globally unique name without hard-coding one.
resource "aws_s3_bucket" "ehr_data" {
  bucket = "${var.project_name}-data-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-ehr-data" }
}

# AES-256 server-side encryption (SSE-S3) — every object encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "ehr_data" {
  bucket = aws_s3_bucket.ehr_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"   # SSE-S3; swap for aws:kms + kms_master_key_id to use the CMK
    }
  }
}

# Block all forms of public access — PHI/de-identified data must never be public
resource "aws_s3_bucket_public_access_block" "ehr_data" {
  bucket                  = aws_s3_bucket.ehr_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CloudTrail Audit Log Bucket ────────────────────────────────────────────
# Dedicated bucket keeps audit logs separate from application data, making
# it easier to apply tighter retention and access policies on logs.
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.project_name}-trail-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-cloudtrail" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail needs explicit bucket-policy permission to check ACLs and write logs
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}
