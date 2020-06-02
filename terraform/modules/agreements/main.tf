##########################################################
# Database: Agreements
#
# Agreements Database
##########################################################

module "globals" {
  source = "../globals"
}

resource "aws_security_group" "allow_postgres_external" {
  name        = "allow_postgres_external"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # Tried limiting egress to web & app subnets - could not get a local connection via SSH tunneling
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "agreements" {
  name       = "main"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "ECS"
  }
}

resource "aws_rds_cluster" "default" {
  cluster_identifier              = "ccs-eu2-${lower(var.environment)}-db-agreements"
  availability_zones              = var.availability_zones
  database_name                   = "agreements"
  master_username                 = var.agreement_db_username
  master_password                 = var.agreement_db_password
  engine                          = "aurora-postgresql"
  apply_immediately               = true
  vpc_security_group_ids          = ["${aws_security_group.allow_postgres_external.id}"]
  deletion_protection             = var.deletion_protection
  db_subnet_group_name            = aws_db_subnet_group.agreements.name
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "final-snaphot-agreements-${uuid()}"

  lifecycle {
    ignore_changes = [
      availability_zones
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count               = 1
  identifier          = "ccs-eu2-${lower(var.environment)}-db-agreements-${count.index}"
  cluster_identifier  = aws_rds_cluster.default.id
  instance_class      = "db.t3.medium"
  engine              = "aurora-postgresql"
  publicly_accessible = true
  apply_immediately   = true

  db_subnet_group_name = aws_db_subnet_group.agreements.name
}
