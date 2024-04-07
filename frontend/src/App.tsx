import {
  Button,
  Container,
  Link,
  Stack,
  Table,
  TableCell,
  TableRow,
  Typography,
} from "@mui/material";
import { GitHub, LinkedIn } from "@mui/icons-material";
import { CopyButton } from "./components/CopyButton";

function App() {
  return (
    <div>
      <Container maxWidth={"sm"}>
        <Typography variant="h2" align="center" gutterBottom>
          Samantha Hughes
        </Typography>
        <Table size="small">
          <TableRow>
            <TableCell>Email:</TableCell>
            <TableCell>
              <Stack direction="row" spacing={2} alignItems="center">
                <Link href="mailto:shughes.uk@gmail.com">
                  shughes.uk@gmail.com
                </Link>
                <CopyButton text="shughes.uk@gmail.com" />
              </Stack>
            </TableCell>
          </TableRow>
          <TableRow>
            <TableCell>Phone:</TableCell>
            <TableCell>
              <Stack direction="row" spacing={2} alignItems="center">
                <Link href="tel:+15129099300">+1-512-909-9300</Link>
                <CopyButton text="+1-512-909-9300" />
              </Stack>
            </TableCell>
          </TableRow>
          <TableRow>
            <TableCell>Social:</TableCell>
            <TableCell sx={{ alignContent: "center" }}>
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
            </TableCell>
          </TableRow>
          <TableRow>
            <TableCell>
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
            </TableCell>
          </TableRow>
        </Table>
      </Container>
    </div>
  );
}

export default App;
