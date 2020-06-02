variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "enabled_cloudwatch_logs_exports" {
  type = list(string)
}

variable "agreement_db_username" {
  type = string
}

variable "agreement_db_password" {
  type = string
}
