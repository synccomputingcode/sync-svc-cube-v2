terraform {
  cloud {
    organization = "synccomputing"
    workspaces {
      name = "sync-svc-cube"
    }

  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket                  = "synccomputing-terraform-state"
    key                     = "sync-svc-cube"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
  }
}
