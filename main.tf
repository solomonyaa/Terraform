terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "the-web-net" {
    source = "./webnet"
}

module "the-web-comp" {
  source = "./webcomp"
  vpc_id             = module.the-web-net.vpc_id
  public_subnet_1_id = module.the-web-net.public_subnet_1_id
  public_subnet_2_id = module.the-web-net.public_subnet_2_id
}
