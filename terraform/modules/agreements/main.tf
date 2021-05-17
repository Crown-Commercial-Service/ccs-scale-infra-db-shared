##########################################################
# Database: Agreements
#
# Agreements Database
##########################################################

module "globals" {
  source = "../globals"
}

data "aws_vpc" "scale" {
  id = var.vpc_id
}

resource "aws_security_group" "allow_postgres_external" {
  name        = "allow_postgres_external"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.scale.cidr_block]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.scale.cidr_block]
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

resource "aws_rds_cluster_parameter_group" "scale" {
  name   = "scale-shared"
  family = "aurora-postgresql11"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "ssl_min_protocol_version"
    value = "TLSv1.2"
  }
}

##################################################################################
# Note: snapshot_identifier can be used to restore to a snapshot when rebuiding
# the database from scratch. As it stands, it will only come into effect on a new
# provisioning (as it is included in the ignore_changes block)
##################################################################################
resource "aws_rds_cluster" "default" {
  cluster_identifier              = "ccs-eu2-${lower(var.environment)}-db-agreements"
  availability_zones              = var.availability_zones
  database_name                   = "agreements"
  master_username                 = data.aws_ssm_parameter.master_username.value
  master_password                 = data.aws_ssm_parameter.master_password.value
  engine                          = "aurora-postgresql"
  engine_version                  = "11.8"
  apply_immediately               = true
  vpc_security_group_ids          = ["${aws_security_group.allow_postgres_external.id}"]
  deletion_protection             = var.deletion_protection
  db_subnet_group_name            = aws_db_subnet_group.agreements.name
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "final-snaphot-agreements-${uuid()}"
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = "00:57-01:27"
  kms_key_id                      = var.kms_key_id
  storage_encrypted               = true
  snapshot_identifier             = var.snapshot_identifier
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.scale.name

  lifecycle {
    ignore_changes = [
      availability_zones,
      snapshot_identifier
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = var.cluster_instances
  identifier           = "ccs-eu2-${lower(var.environment)}-db-agreements-${count.index}"
  cluster_identifier   = aws_rds_cluster.default.id
  instance_class       = "db.t3.medium"
  engine               = "aurora-postgresql"
  apply_immediately    = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.agreements.name
}

# Note: we are using the read-only cluster endpoint - load balanced across read replicas (defined by var.cluster_instances)
resource "aws_ssm_parameter" "instance_endpoint" {
  name      = "${lower(var.environment)}-agreements-db-endpoint"
  type      = "String"
  value     = aws_rds_cluster.default.reader_endpoint
  overwrite = true
}
