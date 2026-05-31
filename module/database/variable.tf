# variable db_subnet_group_name {
#   description = "The name of the DB subnet group"
#   type        = string
# }

variable db_sg_id {
  description = "The ID of the DB security group"
  type        = string
}

variable db_subnet_1_id {
  description = "The ID of the first DB subnet"
  type        = string
}

variable db_subnet_2_id {
  description = "The ID of the second DB subnet"
  type        = string
}