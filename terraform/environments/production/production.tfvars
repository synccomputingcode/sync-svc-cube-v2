env        = "production"
api_domain = "cube-api.synccomputing.com"
vpc_cidr   = "10.0.0.0/16"
cube_api_env_vars = [
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
  },
  {
    name  = "CUBEJS_CACHE_AND_QUEUE_DRIVER"
    value = "cubestore"
  }
]
azs             = ["us-east-1a", "us-east-1b", "us-east-1d", "us-east-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24", "10.0.104.0/24"]