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