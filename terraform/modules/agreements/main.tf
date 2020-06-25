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
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
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

data "aws_ssm_parameter" "master_username" {
  name            = "${lower(var.environment)}-agreements-db-master-username"
  with_decryption = true
}

data "aws_ssm_parameter" "master_password" {
  name            = "${lower(var.environment)}-agreements-db-master-password"
  with_decryption = true
}

resource "aws_rds_cluster" "default" {
  cluster_identifier              = "ccs-eu2-${lower(var.environment)}-db-agreements"
  availability_zones              = var.availability_zones
  database_name                   = "agreements"
  master_username                 = data.aws_ssm_parameter.master_username.value
  master_password                 = data.aws_ssm_parameter.master_password.value
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
  count                = 1
  identifier           = "ccs-eu2-${lower(var.environment)}-db-agreements-${count.index}"
  cluster_identifier   = aws_rds_cluster.default.id
  instance_class       = "db.t3.medium"
  engine               = "aurora-postgresql"
  apply_immediately    = true
  publicly_accessible  = true
  db_subnet_group_name = aws_db_subnet_group.agreements.name
}

resource "aws_ssm_parameter" "instance_endpoint" {
  name      = "${lower(var.environment)}-agreements-db-endpoint"
  type      = "String"
  value     = aws_rds_cluster_instance.cluster_instances[0].endpoint
  overwrite = true
}
