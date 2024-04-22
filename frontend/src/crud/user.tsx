import { useQuery } from "react-query";
import { ApiClient } from "../api";
import { ResponseError, UserSchema } from "../api-client";

export const useMe = () => {
  return useQuery<UserSchema, ResponseError>(["identifyMe"], () => {
    return ApiClient.apiViewsUserIdentify();
  });
};
