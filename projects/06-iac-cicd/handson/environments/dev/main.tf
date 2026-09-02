# environments/dev/main.tf
# modules を組み合わせて dev 環境(VPC + SG + EC2)を構築します。

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
}

module "security_group" {
  source = "../../modules/security_group"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip_cidr   = var.my_ip_cidr
}

module "ec2" {
  source = "../../modules/ec2"

  project_name       = var.project_name
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security_group.web_sg_id]
  instance_type      = var.instance_type
  key_name           = var.key_name
}
