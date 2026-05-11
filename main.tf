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

    tags = {
        Name = "main_eip"
    }
}