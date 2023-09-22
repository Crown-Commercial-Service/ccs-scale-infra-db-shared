#########################################################
# Environment: TST
#
# Deploy SCALE shared databases
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-db-shared-tst"
    region         = "eu-west-2"
    dynamodb_table = "scale_terraform_state_lock"
    encrypt        = true
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

locals {
  environment        = "TST"
  availability_zones = ["eu-west-2a", "eu-west-2b"]
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source                          = "../../modules/configs/deploy-all"
  aws_account_id                  = data.aws_ssm_parameter.aws_account_id.value
  environment                     = local.environment
  availability_zones              = local.availability_zones
  deletion_protection             = false
  skip_final_snapshot             = false
  enabled_cloudwatch_logs_exports = ["postgresql"]
  snapshot_identifier             = "arn:aws:rds:eu-west-2:682179744484:cluster-snapshot:final-snaphot-agreements-d802eec2-f894-a37f-d22d-bbe86a82ca3f"
  transit_gateway_postgres_cidrs = {
    "dmp_cicd" = {
      prefix_list_id = "pl-00c0b3d946c098f84"
    }
  }
}
