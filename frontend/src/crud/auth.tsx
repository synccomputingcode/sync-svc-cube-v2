import { useMutation } from "react-query";
import { ApiClient } from "../api";
import { ResponseError, UserSchema } from "../api-client";
import { useCallback, useContext } from "react";
import { AuthContext } from "../components/context/auth";
import { useNavigate } from "react-router-dom";
import { URLS } from "../urls";

const useOnLogin = () => {
  const { login } = useContext(AuthContext);
  const navigate = useNavigate();
  return useCallback(
    (data: UserSchema) => {
      login(data);
      navigate(URLS.Home, { replace: true });
    },
    [navigate, login],
  );
};

export const useGoogleLoginMutation = () => {
  const loginCallback = useOnLogin();
  return useMutation<UserSchema, ResponseError, string>(
    (accessToken: string) => {
      return ApiClient.apiViewsAuthGoogleLogin({
        socialLoginSchema: {
          accessToken,
        },
      });
    },
    {
      onSuccess: loginCallback,
    },
  );
};

export const useGithubLoginMutation = () => {
  const loginCallback = useOnLogin();
  return useMutation<UserSchema, ResponseError, string>(
    (accessToken: string) => {
      return ApiClient.apiViewsAuthGithubLogin({
        socialLoginSchema: {
          accessToken,
        },
      });
    },
    {
      onSuccess: loginCallback,
    },
  );
};

export const useLogoutMutation = () => {
  return useMutation(() => {
    return ApiClient.apiViewsAuthLogOut();
  });
};
