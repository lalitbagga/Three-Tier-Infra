output "bastion_sg_id" {
    value = aws_security_group.bastion_sg.id
}

output "private_sg_id" {
    value = aws_security_group.private_sg.id
}

output "db_sg_id" {
    value = aws_security_group.db_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "monitoring_sg_id" {
  value = aws_security_group.monitoring_sg.id
}