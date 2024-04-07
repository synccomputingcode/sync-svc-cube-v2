terraform {
  cloud {
    organization = "shughesuk"
    workspaces {
      name = "resume-workspace"
    }

  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.2.0"
}
