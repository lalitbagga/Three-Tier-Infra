output "bastion_sg_id" {
    value = aws_security_group.bastion_sg.id
}

output "private_sg_id" {
    value = aws_security_group.private_sg.id
}

output "db_sg_id" {
    value = aws_security_group.db_sg.id
}