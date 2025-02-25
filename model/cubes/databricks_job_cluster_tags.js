const fetchUniqueTagKeys = require("../fetch").fetchUniqueTagKeys;
 
asyncModule(async () => {
  const sync_tenant_id = COMPILE_CONTEXT.securityContext['https://synccomputing.com/sync_tenant_id_override'] || COMPILE_CONTEXT.securityContext['https://synccomputing.com/sync_tenant_id']
  const uniqueTagKeys = await fetchUniqueTagKeys(sync_tenant_id);

  const createDimension = (tagKey) => ({
    [`tag_${tagKey}`]: {
      sql: (CUBE) => `${CUBE}.tag_${tagKey}`,
      type: `string`,
    },
  })

  const asClause = uniqueTagKeys.map((tagKey) => `tag_${tagKey} TEXT`).join(', ');
 
  cube(`databricks_job_cluster_tags`, {
    sql: `
      SELECT
        tags_join.job_cluster_spec_id,
        cluster_tags.*
      FROM public.databricks_job_cluster_spec_cluster_tags_join AS tags_join
      LEFT OUTER JOIN (
        SELECT *
          FROM crosstab(
              'SELECT id, tag_key, tag_value FROM databricks_cluster_tags WHERE sync_tenant_id = ''${sync_tenant_id}'' ORDER BY id, tag_key',
              'SELECT DISTINCT tag_key FROM databricks_cluster_tags WHERE sync_tenant_id = ''${sync_tenant_id}'' ORDER BY tag_key'
          ) AS ct(id UUID, ${asClause})
      ) AS cluster_tags on tags_join.tag_id = cluster_tags.id
    `,
 
    dimensions: uniqueTagKeys.reduce(
      (all, tagKey) => ({
        ...all,
        ...createDimension(tagKey),
      }),
      {}
    )
  });
});
