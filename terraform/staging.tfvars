env        = "staging"
api_domain = "stage-cube-api.synccomputing.com"
vpc_cidr   = "10.1.0.0/16"
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
    value = "ec2-52-70-190-140.compute-1.amazonaws.com"
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
    value = "dd1o1gh3i6o5f6"
  },
  {
    name  = "CUBEJS_SCHEMA_PATH"
    value = "model"
  },
  {
    name  = "CUBEJS_DEV_MODE"
    value = "true"
  },
  {
    name  = "NODE_ENV",
    value = "production"
  },
  {
    name  = "CUBEJS_JWK_URL"
    value = "https://sync-stage.us.auth0.com/.well-known/jwks.json"
  },
  {
    name  = "CUBEJS_JWT_AUDIENCE"
    value = "https://stage-api.synccomputing.com"
  },
  {
    name  = "CUBEJS_JWT_ISSUER"
    value = "https://login.stage.synccomputing.com/"
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
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24", "10.1.4.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24", "10.1.104.0/24"]