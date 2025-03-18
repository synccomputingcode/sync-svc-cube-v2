module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">=5.7.1"

  name = "${var.env}-vpc"
  cidr = var.vpc_cidr

  azs                  = var.azs
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  create_igw           = true
}

module "cube_cluster" {
  source = "../cube-cluster"

  cluster_prefix       = "${var.env}-sync"
  vpc                  = module.vpc
  cube_api_domain_name = var.api_domain
  cube_shared_env      = var.cube_api_env_vars
  cube_shared_secrets = [
    { name = "CUBEJS_DB_PASS", valueFrom = aws_secretsmanager_secret.postgres_cube_user_pw.arn },
    { name = "CUBEJS_JWT_KEY", valueFrom = aws_secretsmanager_secret.auth0_jwt_key.arn },
  ]
}

resource "aws_secretsmanager_secret" "postgres_cube_user_pw" {
  name = "${var.env}/postgres-cube-user-pw"
}

resource "aws_secretsmanager_secret" "auth0_jwt_key" {
  name = "${var.env}/auth0-jwt-key"
}

resource "aws_iam_openid_connect_provider" "github_openid" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["cf23df2207d99a74fbe169e3eba035e633b65d94"]
}

module "iam_github_oidc_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name        = "${var.env}_github_actions_role"
  path        = "/system/"
  description = "GitHub IAM role for GitHub actions"

  subjects = ["synccomputingcode/sync-svc-cube-v2:*"]

  policies = {
    GitHubActionsPolicy = module.cube_cluster.cube_repo_ecr_policy.arn
  }
}