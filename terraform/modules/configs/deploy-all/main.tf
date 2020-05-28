#########################################################
# Config: deploy-all
#
# This configuration will deploy all components.
#########################################################
provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${lower(var.environment)}-vpc-id"
}

data "aws_ssm_parameter" "private_db_subnet_ids" {
  name = "${lower(var.environment)}-private-db-subnet-ids"
}

module "agreements" {
  source                = "../../agreements"
  environment           = var.environment
  vpc_id                = data.aws_ssm_parameter.vpc_id.value
  availability_zones    = var.availability_zones
  private_db_subnet_ids = split(",", data.aws_ssm_parameter.private_db_subnet_ids.value)
}
