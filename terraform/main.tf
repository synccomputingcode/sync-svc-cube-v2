provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "production"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">=5.7.1"

  name = "production-vpc"
  cidr = "10.0.0.0/16"

  azs                  = ["us-east-1a", "us-east-1b", "us-east-1d", "us-east-1c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24", "10.0.104.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  create_igw           = true
}

module "production_cube_cluster" {
  source = "./modules/cube-cluster"

  cluster_prefix       = "prod-sync"
  vpc                  = module.vpc
  cube_api_domain_name = "cube-api.synccomputing.com"
  cube_shared_env = [
    {
      name  = "CUBEJS_DB_SSL"
      value = "true"
    },
    {
      name  = "CUBEJS_DB_TYPE"
      value = "postgres"
    },
    {
      name  = "CUBEJS_DB_HOST"
      value = "ec2-3-221-59-105.compute-1.amazonaws.com"
    },
    {
      name  = "CUBEJS_DB_PORT"
      value = "5432"
    },
    {
      name  = "CUBEJS_DB_USER"
      value = "cube"
    },
    {
      name  = "CUBEJS_DB_NAME"
      value = "d20nhfliefb6aa"
    },
    {
      name  = "CUBEJS_SCHEMA_PATH"
      value = "model"
    },
    {
      name  = "CUBEJS_DEV_MODE"
      value = "false"
    },
    {
      name  = "NODE_ENV",
      value = "production"
    },
    {
      name  = "CUBEJS_JWK_URL"
      value = "https://sync-prod.us.auth0.com/.well-known/jwks.json"
    },
    {
      name  = "CUBEJS_JWT_AUDIENCE"
      value = "https://api.synccomputing.com"
    },
    {
      name  = "CUBEJS_JWT_ISSUER"
      value = "https://login.app.synccomputing.com/"
    },
    {
      name  = "CUBEJS_JWT_ALGS"
      value = "RS256"
    },
    {
      name  = "CUBEJS_JWT_CLAIMS_NAMESPACE"
      value = "https://synccomputing.com/"
    }
  ]
  cube_shared_secrets = [
    { name = "CUBEJS_DB_PASS", valueFrom = aws_secretsmanager_secret.postgres_cube_user_pw.arn },
    { name = "CUBEJS_JWT_KEY", valueFrom = aws_secretsmanager_secret.auth0_jwt_key.arn },
  ]
}

resource "aws_secretsmanager_secret" "postgres_cube_user_pw" {
  name = "production/postgres-cube-user-pw"
}

resource "aws_secretsmanager_secret" "auth0_jwt_key" {
  name = "production/auth0-jwt-key"
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
  name        = "github_actions_role"
  path        = "/system/"
  description = "GitHub IAM role for GitHub actions"

  subjects = ["synccomputingcode/sync-svc-cube-v2:*"]

  policies = {
    GitHubActionsPolicy = module.production_cube_cluster.cube_repo_ecr_policy.arn
  }
}
