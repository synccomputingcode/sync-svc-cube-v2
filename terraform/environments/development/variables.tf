variable "env" {
  type = string
}

variable "api_domain" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "cube_api_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "azs" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}