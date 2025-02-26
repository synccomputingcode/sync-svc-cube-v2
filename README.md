# sync-svc-cube
A cube dev deployment creating a semantic layer for serving up a connected data model.

## Standing up Cube locally
### Prerequisites
- Your machine is running docker
- You have an Auth0 user

### Standing up Cube locally
1. Create a .env file at the root repo directory and add the following properties and get their values from dev:

    1.1. Add properties and values to setup authentication for auth0:
    ```
    CUBEJS_JWK_URL
    CUBEJS_JWT_AUDIENCE
    CUBEJS_JWT_ISSUER
    CUBEJS_JWT_ALGS
    CUBEJS_JWT_CLAIMS_NAMESPACE
    ```

    1.2. Add properties to connect to different Sync datastores like Postgres and Databricks Delta Tables
    ```
    CUBEJS_DB_HOST
    CUBEJS_DB_PORT
    CUBEJS_DB_NAME
    CUBEJS_DB_USER
    CUBEJS_DB_PASS
    CUBEJS_DB_TYPE
    ```

2. Build docker image `docker build -t sync-cube-image .`

3. Run `docker compose up`

4. Run `curl -X GET 'http://localhost:4000/livez'` to ensure cube is properly running

5. You should now have a running cube server! Happy cubing! You can navigate to `http://localhost:4000/` to play with the cube playground.


## Helpful Cube Dev documentation:
* https://cube.dev/
* https://github.com/cube-js/cube