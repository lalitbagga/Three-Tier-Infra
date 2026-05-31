resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Admin1234!"
  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  vpc_security_group_ids = [var.db_sg_id]
  skip_final_snapshot    = true

  tags = {
    Name = "db_private"
  }
}

resource "aws_db_subnet_group" "db_group" {
  name       = "db_subnet_group"
  subnet_ids = [var.db_subnet_1_id, var.db_subnet_2_id]

  tags = {
    Name = "db_subnet_group"
  }
}