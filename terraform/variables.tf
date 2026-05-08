# ── Input Variables ────────────────────────────────────────────────────────
# Override any of these via terraform.tfvars or -var flags.

variable "aws_region" {
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short prefix applied to every resource name"
  default     = "ehr-demo"
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance"
  default     = "ehradmin"
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance (keep out of source control)"
  default     = "EhrD3m0Pass!"
  sensitive   = true
}
