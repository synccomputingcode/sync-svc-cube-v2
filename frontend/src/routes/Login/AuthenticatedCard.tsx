import {
  Button,
  Card,
  CardContent,
  Divider,
  Stack,
  Typography,
} from "@mui/material";
import { useContext } from "react";
import { AuthContext } from "../../components/context/auth";

export const AuthenticatedCard = (): React.ReactElement => {
  const { user, logout } = useContext(AuthContext);
  return (
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
  );
};
