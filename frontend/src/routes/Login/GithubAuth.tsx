import { Button } from "@mui/material";
import React, { useContext, useEffect } from "react";
import { useGithubLoginMutation } from "../../crud/auth";
import { AuthContext } from "../../components/context/auth";
import { GitHub } from "@mui/icons-material";
import { useNavigate, useSearchParams } from "react-router-dom";

let DoneGithubCallback = false;

export const GithubCallback = (): React.ReactElement => {
  // token is stored as "code" in the URL query string
  const [searchParams] = useSearchParams();
  const code = searchParams.get("code");
  const { login } = useContext(AuthContext);
  const navigate = useNavigate();
  const { mutate } = useGithubLoginMutation();
  useEffect(() => {
    if (code && !DoneGithubCallback) {
      mutate(code);
      DoneGithubCallback = true;
    }
  }, [code, mutate, login, navigate]);

  return <></>;
};

export const GithubAuth = (): React.ReactElement => {
  return (
    <Button
      onClick={() => {
        const params = new URLSearchParams({
          client_id: import.meta.env.VITE_GITHUB_CLIENT_ID,
          redirect_uri: `${window.location.origin}/github/callback`,
          scope: "read:user, user:email",
        });
        window.location.href = `https://github.com/login/oauth/authorize?${params.toString()}`;
      }}
      variant="contained"
      startIcon={<GitHub />}
    >
      Continue with GitHub
    </Button>
  );
};
