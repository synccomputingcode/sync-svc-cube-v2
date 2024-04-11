import { UseQueryResult, useQuery } from "react-query";
import { ApiClient } from "../../api";

export const useHealthcheck = (): UseQueryResult<void> => {
  return useQuery<void>(["healthcheck"], ({ signal }) =>
    ApiClient.resumeApiHello({
      signal,
    }),
  );
};
