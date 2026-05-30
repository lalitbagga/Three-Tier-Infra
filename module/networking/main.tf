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