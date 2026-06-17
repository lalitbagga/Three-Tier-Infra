output vpc_id {
  value = aws_vpc.main.id
}

output "main_subnet_public_1_id" {
  value = aws_subnet.main_subnet_public_1.id
}

output "main_subnet_private_1_id" {
  value = aws_subnet.main_subnet_private_1.id
}

//aws_subnet.db_subnet_2.id
output "db_subnet_1_id" {
  value = aws_subnet.db_subnet_1.id
}

output "db_subnet_2_id" {
  value = aws_subnet.db_subnet_2.id
}

output "main_subnet_public_2_id" {
  value = aws_subnet.main_subnet_public_2.id
}