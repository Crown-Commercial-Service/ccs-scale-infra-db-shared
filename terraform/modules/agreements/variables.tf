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
