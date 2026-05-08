# ── Security Group ─────────────────────────────────────────────────────────
# Allows PostgreSQL traffic only from resources inside the VPC (e.g. Lambda, EC2).
# No public inbound access is permitted.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL (5432) from within the VPC only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# ── DB Subnet Group ────────────────────────────────────────────────────────
# AWS requires a subnet group to span at least two Availability Zones
resource "aws_db_subnet_group" "ehr" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# ── RDS PostgreSQL Instance ────────────────────────────────────────────────
# Stores EHR metadata (patient IDs, visit records, etc.) in the private subnet.
# Storage is encrypted with the project KMS key.
resource "aws_db_instance" "ehr" {
  identifier        = "${var.project_name}-ehr-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"   # smallest tier — fine for a demo
  allocated_storage = 20

  db_name  = "ehrmetadata"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.ehr.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  storage_encrypted   = true
  kms_key_id          = aws_kms_key.ehr.arn
  publicly_accessible = false   # never expose the database to the internet

  # Skipping the final snapshot is acceptable for a demo environment only
  skip_final_snapshot = true

  tags = { Name = "${var.project_name}-ehr-db" }
}
