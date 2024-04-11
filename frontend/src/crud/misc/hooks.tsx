import { UseQueryResult, useQuery } from "react-query";
import { ApiClient } from "../../api";
import { HealthCheckSchema } from "../../api-client";

export const useHealthcheck = (): UseQueryResult<void> => {
  return useQuery<HealthCheckSchema>(["healthcheck"], ({ signal }) =>
    ApiClient.resumeApiHello({
      signal,
    }),
  );
};
