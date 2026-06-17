terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  backend "s3" {
    bucket       = "three-tier-tf-state-us-east-2"
    key          = "three-tier/terraform.tfstate"
    region       = "us-east-2"
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

}
module "database" {
  source         = "./module/database"
  db_sg_id       = module.security.db_sg_id
  db_subnet_1_id = module.networking.db_subnet_1_id
  db_subnet_2_id = module.networking.db_subnet_2_id
}

module "compute" {
  source                   = "./module/compute"
  main_subnet_public_1_id  = module.networking.main_subnet_public_1_id
  bastion_sg_id            = module.security.bastion_sg_id
  main_subnet_private_1_id = module.networking.main_subnet_private_1_id
  private_sg_id            = module.security.private_sg_id
}
module "ecr" {
  source = "./module/ecr"
}

module "ecs" {
  source             = "./module/ecs"
  private_subnet_id  = module.networking.main_subnet_private_1_id
  ecs_sg_id          = module.security.ecs_sg_id
  ecr_repository_url = module.ecr.repository_url
  target_group_arn   = module.alb.target_group_arn
  alb_listener_arn   = module.alb.alb_listener_arn
}

module "alb" {
  source              = "./module/alb"
  vpc_id              = module.networking.vpc_id
  alb_sg_id          = module.security.alb_sg_id
  public_subnet_1_id = module.networking.main_subnet_public_1_id
  public_subnet_2_id = module.networking.main_subnet_public_2_id
}
