# ── CloudTrail ─────────────────────────────────────────────────────────────
# Records every AWS API call made in this account/region. This satisfies the
# HIPAA requirement for a comprehensive audit trail of PHI-adjacent activity.
resource "aws_cloudtrail" "ehr" {
  name           = "${var.project_name}-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  include_global_service_events = true    # captures IAM, STS, and other global APIs
  is_multi_region_trail         = false   # single-region for the demo
  enable_log_file_validation    = true    # SHA-256 digest files detect log tampering

  # Encrypt log files with the project KMS CMK
  kms_key_id = aws_kms_key.ehr.arn

  tags = { Name = "${var.project_name}-audit-trail" }

  # The bucket policy granting CloudTrail write access must exist first
  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
