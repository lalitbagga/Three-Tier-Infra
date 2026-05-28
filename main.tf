locals {
  cloudwatch_user_data = <<-EOF
    #!/bin/bash

    yum update -y
    yum install -y amazon-cloudwatch-agent

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c ssm:/cloudwatch-agent/config \
      -s
  EOF
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}
provider "aws" {
  region = "us-east-2"
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  //enable_dns_support

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_gateway"
  }
}

resource "aws_subnet" "main_subnet_public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "main_subnet_public_1"
  }
}

resource "aws_subnet" "main_subnet_public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "main_subnet_public_2"
  }
}

resource "aws_subnet" "main_subnet_private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "main_subnet_private_1"
  }
}

resource "aws_subnet" "main_subnet_private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "main_subnet_private_2"
  }
}
resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "db_subnet_1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "db_subnet_2"
  }
}

resource "aws_eip" "main_elastic_ip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main_internet_gateway]
  tags = {
    Name = "main_eip"
  }
}

resource "aws_nat_gateway" "main_nat_gateway" {
  allocation_id = aws_eip.main_elastic_ip.id
  subnet_id     = aws_subnet.main_subnet_public_2.id

  tags = {
    Name = "main_nat_gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_route_table" "main_public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_internet_gateway.id
  }

  tags = {
    Name = "main_public_route_table"
  }
}

resource "aws_route_table" "main_private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat_gateway.id
  }

  tags = {
    Name = "main_private_route_table"
  }
}

resource "aws_route_table_association" "main_route_table_association" {
  subnet_id      = aws_subnet.main_subnet_public_1.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_2" {
  subnet_id      = aws_subnet.main_subnet_public_2.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_3" {
  subnet_id      = aws_subnet.main_subnet_private_1.id
  route_table_id = aws_route_table.main_private_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_4" {
  subnet_id      = aws_subnet.main_subnet_private_2.id
  route_table_id = aws_route_table.main_private_route_table.id
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion_sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bastion_sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "174.114.38.31/32"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.bastion_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("~/.ssh/bastion-key.pub")
}

//Create ec2 instance for bastion host
resource "aws_instance" "bastion_host" {
  ami                         = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main_subnet_public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_key.key_name
  tags = {
    Name = "bastion_host"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = local.cloudwatch_user_data
}

//Setup for private instance

resource "aws_security_group" "private_sg" {
  name   = "private_sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private_sg"
  }
}

//allow SSH access from the bastion host's security group
resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress" {
  security_group_id            = aws_security_group.private_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_vpc_security_group_egress_rule" "private_sg_egress" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_instance" "private_host" {
  ami                         = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main_subnet_private_1.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.bastion_key.key_name
  tags = {
    Name = "private_host"
  }
}

//DB setup

resource "aws_security_group" "db_sg" {
  name   = "db_sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "db_sg"
  }
}

//allow MySQL access from the private host's security group
resource "aws_vpc_security_group_ingress_rule" "db_sg_ingress" {
  security_group_id            = aws_security_group.db_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private_sg.id
}

resource "aws_vpc_security_group_egress_rule" "db_sg_egress" {
  security_group_id = aws_security_group.db_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "db_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]

  tags = {
    Name = "db_subnet_group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Admin1234!"
  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "db_private"
  }
}
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2_role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

//store the config in SSM:
resource "aws_ssm_parameter" "cloudwatch_config" {
  name  = "/cloudwatch-agent/config"
  type  = "String"
  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path        = "/var/log/messages"
              log_group_name   = "ec2-logs"
              log_stream_name  = "{instance_id}"
            }
          ]
        }
      }
    }
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}