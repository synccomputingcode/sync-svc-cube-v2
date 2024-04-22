import { Stack, Typography } from "@mui/material";
import Grid2 from "@mui/material/Unstable_Grid2/Grid2";
import { GetInTouchCard } from "./GetInTouchCard";
import { LoginCard } from "./LoginCard";
import { useContext } from "react";
import { AuthContext } from "../../components/context/auth";
import { AuthenticatedCard } from "./AuthenticatedCard";
import { SkyBox } from "../../components/SkyBox";

export const LoginView = (): React.ReactElement => {
  const { user } = useContext(AuthContext);
  return (
    <SkyBox>
      <Grid2
        container
        sx={{ paddingTop: { xs: "50px", sm: "120px" }, margin: 0 }}
        spacing={2}
        justifyContent={"center"}
        alignItems={"center"}
      >
        <Grid2 md={6} sx={{ minWidth: "fit-content" }}>
          <Typography
            variant={"h1"}
            sx={{
              fontWeight: "600",
              fontSize: (theme) => ({
                xs: "2rem",
                md: theme.typography.h1.fontSize,
              }),
            }}
          >
            Samantha Hughes
          </Typography>
          <Typography
            variant="h2"
            sx={{
              whiteSpace: "nowrap",
              fontSize: (theme) => ({
                xs: "1.5rem",
                md: theme.typography.h2.fontSize,
              }),
            }}
          >
            Full Stack Engineer
          </Typography>
        </Grid2>
        <Grid2
          md={4}
          smOffset={0}
          mdOffset={1}
          sx={{
            maxWidth: "500px",
            minWidth: "fit-content",
          }}
        >
          <Stack spacing={2}>
            <GetInTouchCard />
            {user ? <AuthenticatedCard /> : <LoginCard />}
          </Stack>
        </Grid2>
      </Grid2>
    </SkyBox>
  );
};
