# ── Terraform & Provider Configuration ────────────────────────────────────
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Used by lambda.tf to package the Node.js handler into a ZIP
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Exposes the current AWS account ID — used in bucket names and IAM policies
data "aws_caller_identity" "current" {}
