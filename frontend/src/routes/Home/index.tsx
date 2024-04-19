import {
  Box,
  Button,
  Card,
  CardContent,
  Divider,
  Stack,
  Typography,
} from "@mui/material";
import Grid2 from "@mui/material/Unstable_Grid2/Grid2";
import { GetInTouchCard } from "../Login/GetInTouchCard";
import { useContext } from "react";
import { AuthContext } from "../../components/context/auth";

export function HomeView(): React.ReactElement {
  const { user, logout } = useContext(AuthContext);
  return (
    <Box
      sx={{
        background: (theme) => theme.palette.gradient.default,
        minHeight: "100dvh",
      }}
    >
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
            color="primary.contrastText"
          >
            Samantha Hughes
          </Typography>
          <Typography
            variant="h2"
            color="primary.contrastText"
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
        <Grid2>
          <Stack spacing={2}>
            <GetInTouchCard />
            <Card elevation={10}>
              <CardContent>
                <Stack spacing={1}>
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 600, whiteSpace: "nowrap" }}
                  >
                    Hi {user?.firstName}!
                  </Typography>
                  <Divider />
                  <Typography>You can log out if you want.</Typography>
                  <Button variant="outlined" onClick={logout}>
                    Log Out
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Stack>
        </Grid2>
      </Grid2>
    </Box>
  );
}
