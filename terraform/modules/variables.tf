variable "cluster_prefix" {
  type = string
}

variable "vpc" {
  type = object({
    id              = string
    public_subnets  = list(string)
    private_subnets = list(string)
  })
}

data "aws_vpc" "selected" {
  id = var.vpc.id
}

data "aws_nat_gateway" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc.id]
  }
}

data "aws_internet_gateway" "selected" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc.id]
  }
}

resource "null_resource" "validate_vpc" {
  lifecycle {
    precondition {
      condition     = data.aws_vpc.selected.enable_dns_support
      error_message = "The VPC must have enable_dns_support = true"
    }

    precondition {
      condition     = data.aws_vpc.selected.enable_dns_hostnames
      error_message = "The VPC must have enable_dns_hostnames = true"
    }

    precondition {
      condition     = length(data.aws_nat_gateway.selected.ids) > 0
      error_message = "The VPC must have at least one NAT Gateway"
    }

    precondition {
      condition     = length(data.aws_internet_gateway.selected.ids) > 0
      error_message = "The VPC must have an Internet Gateway"
    }
  }
}

variable "cubestore_image" {
  type        = string
  description = "Image for cube store and cube store router"
  default     = "cubejs/cubestore"
}

variable "cube_api_resources" {
  type = object({
    cpu                  = string
    memory               = string
    desired_worker_count = number
  })

  default = {
    cpu                  = "2048"
    memory               = "4096"
    desired_worker_count = 2
  }
}

variable "cube_refresh_worker_resources" {
  type = object({
    cpu                  = string
    memory               = string
    desired_worker_count = number
  })

  default = {
    cpu                  = "2048"
    memory               = "4096"
    desired_worker_count = 1
  }
}


variable "cubestore_router_resources" {
  type = object({
    cpu                  = string
    memory               = string
    desired_worker_count = number
  })

  default = {
    cpu    = "4096"
    memory = "8192"
  }
}

variable "cubestore_worker_resources" {
  type = object({
    cpu                    = string
    memory                 = string
    cubestore_worker_count = number
  })

  default = {
    cpu                    = "4096"
    memory                 = "8192"
    cubestore_worker_count = 2
  }
}

variable "cube_shared_env" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Shared environment variables for cube api and refresh workers."
  default     = []
}

variable "cube_shared_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Shared environment secrets for cube api and refresh workers."
  default     = []
}

variable "cube_api_domain_name" {
  type = string
}