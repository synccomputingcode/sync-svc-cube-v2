import { useMutation } from "react-query";
import { ApiClient } from "../api";
import { ResponseError, UserSchema } from "../api-client";

export const useGoogleLoginMutation = () => {
  return useMutation<UserSchema, ResponseError, string>(
    (accessToken: string) => {
      return ApiClient.resumeViewsAuthGoogleLogin({
        socialLoginSchema: {
          accessToken,
        },
      });
    },
  );
};

export const useLogoutMutation = () => {
  return useMutation(() => {
    return ApiClient.resumeViewsAuthLogOut();
  });
};
