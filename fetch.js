const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.CUBEJS_DB_HOST,
  port: process.env.CUBEJS_DB_PORT,
  user: process.env.CUBEJS_DB_USER,
  password: process.env.CUBEJS_DB_PASS,
  database: process.env.CUBEJS_DB_NAME,
  ssl: {
    rejectUnauthorized: false  // Heroku requires SSL but with this flag off
  },
});
const tenantIdClaim = "https://synccomputing.com/sync_tenant_id";

 
exports.fetchUniqueTagKeys = async (sync_tenant_id) => {
  let client;
  let tagKeys = [];
  try {
    console.log("looking up tags for: ", sync_tenant_id);
    client = await pool.connect();
    const uniqueTagKeysQuery = `
SELECT DISTINCT tag_key
FROM public.databricks_cluster_tags
WHERE sync_tenant_id = '${sync_tenant_id}'
`;
    const result = await client.query(uniqueTagKeysQuery);
    // remove special characters from the tag key name so we can expose as a dimension
    tagKeys = result.rows.map((row) => row.tag_key.replace(/[^a-zA-Z0-9_]/g, '_'));
  } catch(error) {
    console.error(error)
  } finally {
    if (client) {
      client.release();
    }
  }

  return tagKeys;
};

exports.fetchUniqueTenants = async () => {
    console.log("trying to fetch unique tenants")
    let client;
    let uniqueTenants = [];
    try {
        client = await pool.connect();
        const uniqueTenantsQuery = `
SELECT DISTINCT sync_tenant_id
FROM public.user
WHERE sync_tenant_id IS NOT NULL and last_login > NOW() - INTERVAL '30 days';
`;
        const result = await client.query(uniqueTenantsQuery);
        console.log(result);
        uniqueTenants = result.rows.map((row) => {
            const secContext = { "securityContext": {}};
            secContext["securityContext"][tenantIdClaim] = row.sync_tenant_id;

            return secContext;
        });
    } catch(error) {
        console.error('Error fetching unique tenants:', error);
    } finally {
        if (client) {
            client.release();
        }
    }
    console.log("Found tenants: " + uniqueTenants)
    return uniqueTenants
}
  