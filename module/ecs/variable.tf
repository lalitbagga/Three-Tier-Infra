variable "private_subnet_id" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}