# ── KMS Customer-Managed Key ───────────────────────────────────────────────
# Single CMK used across RDS storage encryption and CloudTrail log encryption.
# Centralising encryption keys simplifies auditing and key lifecycle management.
resource "aws_kms_key" "ehr" {
  description             = "EHR demo — encryption key for data at rest"
  deletion_window_in_days = 7    # minimum allowed; increase for production
  enable_key_rotation     = true # AWS rotates the key material annually

  # Key policy: account root gets full control; CloudTrail is allowed to
  # generate data keys so it can encrypt log files with this CMK.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrailEncryption"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.project_name}-kms-key" }
}

# Human-readable alias so the key is easy to find in the AWS Console
resource "aws_kms_alias" "ehr" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.ehr.key_id
}
