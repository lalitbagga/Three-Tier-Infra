terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
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
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "main_subnet_public_1"
    }
}

resource "aws_subnet" "main_subnet_public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"

    tags = {
      Name = "main_subnet_public_2"
    }
}

resource "aws_subnet" "main_subnet_private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"

    tags = {
      Name = "main_subnet_private_1"
    }
}

resource "aws_subnet" "main_subnet_private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.4.0/24"

    tags = {
      Name = "main_subnet_private_2"
    }
}

resource "aws_eip" "main_elastic_ip" {
    domain = "vpc"
    depends_on = [ aws_internet_gateway.main_internet_gateway ]
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
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main_nat_gateway.id
    }

    tags = {
      Name = "main_private_route_table"
    }
}

resource "aws_route_table_association" "main_route_table_association" {
  subnet_id = aws_subnet.main_subnet_public_1.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_2" {
  subnet_id = aws_subnet.main_subnet_public_2.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_3" {
  subnet_id = aws_subnet.main_subnet_private_1.id
  route_table_id = aws_route_table.main_private_route_table.id
}

resource "aws_route_table_association" "main_route_table_association_4" {
  subnet_id = aws_subnet.main_subnet_private_2.id
  route_table_id = aws_route_table.main_private_route_table.id
}

resource "aws_security_group" "bastion_sg" {
  name = "bastion_sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bastion_sg" 
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.bastion_sg.id
    from_port         = 22
    to_port           = 22
    ip_protocol =  "tcp"
    cidr_ipv4       = "174.114.52.173/32"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
    security_group_id = aws_security_group.bastion_sg.id
    ip_protocol =  "-1"
    cidr_ipv4       = "0.0.0.0/0" 
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("~/.ssh/bastion-key.pub")
}

//Create ec2 instance for bastion host
resource "aws_instance" "bastion_host" {
  ami           = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main_subnet_public_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.bastion_key.key_name
    tags = {
        Name = "bastion_host"
    }
}

//Setup for private instance

resource "aws_security_group" "private_sg" {
  name = "private_sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private_sg"
  }
}

//allow SSH access from the bastion host's security group
resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress" {
    security_group_id = aws_security_group.private_sg.id
    from_port         = 22
    to_port           = 22
    ip_protocol       = "tcp"
    referenced_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_vpc_security_group_egress_rule" "private_sg_egress" {
    security_group_id = aws_security_group.private_sg.id
    ip_protocol       = "-1"
    cidr_ipv4       = "0.0.0.0/0"
}
resource "aws_instance" "private_host" {
  ami           = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main_subnet_private_1.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name = aws_key_pair.bastion_key.key_name
    tags = {
        Name = "private_host"
    }
}