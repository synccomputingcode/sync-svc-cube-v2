terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket                  = "synccomputing-terraform-state"
    key                     = "sync-svc-cube/development/terraform.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
  }
}

module "sync" {
  source = "../../modules/sync"

  env               = var.env
  api_domain        = var.api_domain
  vpc_cidr          = var.vpc_cidr
  azs               = var.azs
  private_subnets   = var.private_subnets
  public_subnets    = var.public_subnets
  cube_api_env_vars = var.cube_api_env_vars
}