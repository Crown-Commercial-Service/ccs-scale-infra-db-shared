variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "private_db_subnet_ids" {
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

variable "backup_retention_period" {
  type = number
}

variable "cluster_instances" {
  type = number
}

variable "snapshot_identifier" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "transit_gateway_postgres_cidrs" {
  type = map(object({
    prefix_list_id = string
  }))
  default = {}
}
