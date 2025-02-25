const fetchUniqueTenants = require("./fetch").fetchUniqueTenants;
const fetch = require("node-fetch");
const tenantIdClaim = "https://synccomputing.com/sync_tenant_id";
const tenantIdOverrideClaim = "https://synccomputing.com/sync_tenant_id_override";
const cubeBasePath = "/sync-query";
const port = process.env.PORT || 4000;

exports.logger = (message, params) => {
  console.log(JSON.stringify({ message, params }));
};

exports.telemetry = false;
exports.basePath = cubeBasePath;
exports.http = {
  "cors": {
    "allowedHeaders": ["*"],
  }
};
exports.scheduledRefreshTimer = 60 * 60 * 24; // this refreshs our data models every 24 hours


exports.contextToAppId = ({ securityContext }) => {
  const syncTenantId = securityContext[tenantIdOverrideClaim] || 
                         securityContext[tenantIdClaim];

  if (!syncTenantId) {
      throw new Error("You shall not pass! 🧙");
  }

  return `tenant_${syncTenantId}`;
};

exports.extendContext = (req) => {
  return {
    securityContext: {
      ...req.securityContext,
      token: req.headers.authorization,    
    }
  }
}

exports.scheduledRefreshContexts = async () => {
  console.log("Running refresh contexts");
  const uniqueTenants = await fetchUniqueTenants();
  console.log(uniqueTenants);
  return uniqueTenants;
};


async function getCubeMeta(token) {
  const CUBEJS_API_URL = `http://localhost:${port}`;

  try {
    const response = await fetch(`${CUBEJS_API_URL}${cubeBasePath}/v1/meta`, {
      method: "GET",
      headers: {
        Authorization: token,
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error trying to retrieve cube metadata: ${response.status}`);
    }

    const metaData = await response.json();
    return metaData;
  } catch (err) {
    console.error("Error fetching cube metadata:", err.message);
  }
}

const findAuxiliarySortDimFromCube = (cube, dim) => {
  const auxDim = cube.dimensions.find( (cubeDim) => {
    console.debug(`comparing ${cube.name}._sort_${dim} to ${cubeDim.name}`);
    return `${cube.name}._sort_${dim}` == cubeDim.name;
  });
  console.log(`Found aux sort dim ${JSON.stringify(auxDim)}`);
  return auxDim;
}

const findAuxiliarySortDim = (cubeOrViewName, dimension, metadata) => {
  console.debug(`finding aux dims for: ${cubeOrViewName} ${dimension}`);

  let cube = metadata.cubes.find((model) => model.name == cubeOrViewName);
  if (cube.type == "view") {
    // get the og cube from the view's dimension
    const viewDimension = cube.dimensions.find( (cubeDim) => cubeDim.name == `${cubeOrViewName}.${dimension}` );
    const parts = viewDimension.aliasMember.split(".");
    const cubeFromAliasMember = parts[0];
    cube = metadata.cubes.find((model) => model.name == cubeFromAliasMember);
    dimension = parts[1];
    console.debug(`Found og cube from view: ${cube.name} ${dimension}`)
  }
  
  const auxSortDim = findAuxiliarySortDimFromCube(cube, dimension);

  return auxSortDim;
}

const maybeUseAuxilarySortDim = (orderByClause, metadata) => {
  const orderByPath = orderByClause[0]
  const orderByDirection = orderByClause[1] // desc vs asc
  const [cubeOrViewName, dim] = orderByPath.split(".");
  const auxSortByDim = findAuxiliarySortDim(cubeOrViewName, dim, metadata);

  if (auxSortByDim && orderByDirection == "desc") {
    // We only need to use an auxilary sort dimension to sort nulls last if descending order.
    // Ascending order will already sort nulls last.
    return [auxSortByDim.name, orderByDirection];
  } else {
    return orderByClause;
  }
};

const replaceOrderBy = (order, metadata) => {
  const orderByQueries = [];
  if (order && order.length > 0) {
    order.forEach((orderByClause) => {
      let newOrderDim = maybeUseAuxilarySortDim(orderByClause, metadata)
      if (newOrderDim) {
        orderByQueries.push(newOrderDim);
      } else {
        orderByQueries.push(orderByClause);
      }
     
    });
  }
  return orderByQueries;
};

exports.queryRewrite = async (query, { securityContext }) => {
  if (query.order && query.order.length > 0 && query.ungrouped) { // we can skip if customer isn't ordering by anything
    const metadata = await getCubeMeta(securityContext.token);
    query.order = replaceOrderBy(query.order, metadata);
    query.order.forEach((orderClause) => {
      let orderByDimName = orderClause[0];
      if (!query.dimensions.includes(orderByDimName)) {
        // We must add the auxiliary sort dimension in order for sorting to work
        query.dimensions.push(orderByDimName);
      }
    });
    console.log(`Rewritten query: ${JSON.stringify(query)}`)
  }
  return query;
};