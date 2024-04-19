import { Card, CardContent, Divider, Stack, Typography } from "@mui/material";
import React from "react";
import { GoogleAuth } from "./GoogleAuth";
export const LoginCard = (): React.ReactElement => {
  return (
    <Card elevation={10}>
      <CardContent>
        <Stack spacing={1}>
          <Typography
            variant="h5"
            sx={{ fontWeight: 600, whiteSpace: "nowrap" }}
          >
            Explore the Application
          </Typography>
          <Divider />
          <GoogleAuth />
        </Stack>
      </CardContent>
    </Card>
  );
};
