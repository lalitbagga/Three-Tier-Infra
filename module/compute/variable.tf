variable "main_subnet_public_1_id" {
  description = "ID of the first public subnet for the bastion host"
  type        = string
}

variable "bastion_sg_id" {
  description = "ID of the security group for the bastion host"
  type        = string
}

variable "main_subnet_private_1_id" {
  description = "ID of the first private subnet for the private host"
  type        = string
}

variable "private_sg_id" {
  description = "ID of the security group for the private host"
  type        = string
}

variable "monitoring_sg_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}
