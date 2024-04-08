import { GitHub, Group, LinkedIn, Mail, Phone } from "@mui/icons-material";
import {
  Box,
  Button,
  Card,
  CardContent,
  Divider,
  Link,
  List,
  ListItem,
  ListItemIcon,
  ListItemSecondaryAction,
  ListItemText,
  Stack,
  Typography,
} from "@mui/material";
import Grid2 from "@mui/material/Unstable_Grid2/Grid2";
import { CopyButton } from "../components/CopyButton";

export function LoginView(): React.ReactElement {
  return (
    <Box
      sx={{
        backgroundImage:
          "linear-gradient(to right top, rgb(56, 67, 139), rgb(148, 75, 148), rgb(215, 90, 136), rgb(255, 126, 113), rgb(255, 178, 95), rgb(255, 235, 104))",
        height: "100%",
        position: "fixed",
        bottom: "0",
        right: "0",
        left: "0",
      }}
    >
      <Grid2
        container
        sx={{ paddingTop: "120px" }}
        spacing={2}
        justifyContent={"center"}
        alignItems={"center"}
      >
        <Grid2 md={6} sx={{ minWidth: "fit-content" }}>
          <Typography
            variant={"h1"}
            sx={{ fontWeight: "600" }}
            color="primary.contrastText"
          >
            Samantha Hughes
          </Typography>
          <Typography
            variant="h2"
            color="primary.contrastText"
            sx={{ whiteSpace: "nowrap" }}
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
          <Card elevation={10}>
            <CardContent>
              <Stack spacing={1}>
                <Stack>
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 600, whiteSpace: "nowrap" }}
                  >
                    Get In Touch
                  </Typography>
                </Stack>
                <Divider />
                <List dense>
                  <ListItem>
                    <ListItemIcon>
                      <Mail />
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Link href="mailto:shughes.uk@gmail.com">
                          shughes.uk@gmail.com
                        </Link>
                      }
                    />
                    <ListItemSecondaryAction>
                      <CopyButton text="shughes.uk@gmail.com" />
                    </ListItemSecondaryAction>
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <Phone />
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Link href="tel:+15129099300">+1-512-909-9300</Link>
                      }
                    />
                    <ListItemSecondaryAction>
                      <CopyButton text="+1-512-909-9300" />
                    </ListItemSecondaryAction>
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <Group />
                    </ListItemIcon>
                    <ListItemIcon>
                      <Stack direction="row" spacing={1} alignItems={"center"}>
                        <Link
                          href="https://www.linkedin.com/in/samantha-hughes-2b8b7716"
                          target="_blank"
                          rel="noreferrer"
                        >
                          <LinkedIn />
                        </Link>
                        <Link
                          href="https://github.com/shughes-uk"
                          target="_blank"
                          rel="noreferrer"
                        >
                          <GitHub htmlColor="black" />
                        </Link>
                      </Stack>
                    </ListItemIcon>
                  </ListItem>
                </List>
                <Button
                  component={Link}
                  size="small"
                  variant="contained"
                  href="https://calendly.com/shughes-uk/30min"
                  target="_blank"
                  rel="noreferrer"
                >
                  Schedule a call
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid2>
      </Grid2>
    </Box>
  );
}
