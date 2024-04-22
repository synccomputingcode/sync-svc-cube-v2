import { UseQueryResult, useQuery } from "react-query";
import { HealthCheckSchema } from "../api-client";
import { ApiClient } from "../api";

export const useHealthcheck = (): UseQueryResult<HealthCheckSchema> => {
  return useQuery<HealthCheckSchema>(["healthcheck"], ({ signal }) =>
    ApiClient.apiApiHello({
      signal,
    }),
  );
};
