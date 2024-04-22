import { Button } from "@mui/material";
import { useGoogleLogin } from "@react-oauth/google";
import React, { useContext } from "react";
import { useGoogleLoginMutation } from "../../crud/auth";
import GoogleIcon from "../../components/icons/google";
import { AuthContext } from "../../components/context/auth";
export const GoogleAuth = (): React.ReactElement => {
  const { login: authLogin } = useContext(AuthContext);
  const { mutate } = useGoogleLoginMutation();
  const login = useGoogleLogin({
    onSuccess: (codeResponse) =>
      mutate(codeResponse.access_token, {
        onSuccess: (data) => {
          authLogin(data);
        },
      }),
  });
  return (
    <Button
      onClick={() => login()}
      variant="contained"
      startIcon={<GoogleIcon />}
    >
      Continue with Google
    </Button>
  );
};
