terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  backend "s3" {
    bucket =  "three-tier-tf-state-us-east-2"
    key    = "three-tier/terraform.tfstate"
    region = "us-east-2"
    use_lockfile = true
  }

  required_version = ">= 1.2"
}
provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "./module/networking"
}

module "security" {
  source = "./module/security"
  vpc_id = module.networking.vpc_id
  db_subnet_1_id = module.networking.db_subnet_1_id
  db_subnet_2_id = module.networking.db_subnet_2_id
}

module "compute" {
  source = "./module/compute"
  main_subnet_public_1_id = module.networking.main_subnet_public_1_id
  bastion_sg_id = module.security.bastion_sg_id
  main_subnet_private_1_id = module.networking.main_subnet_private_1_id
  private_sg_id = module.security.private_sg_id
}

//DB setup
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Admin1234!"
  db_subnet_group_name   = module.security.db_subnet_group_name
  vpc_security_group_ids = [module.security.db_sg_id]
  skip_final_snapshot    = true

  tags = {
    Name = "db_private"
  }
}
