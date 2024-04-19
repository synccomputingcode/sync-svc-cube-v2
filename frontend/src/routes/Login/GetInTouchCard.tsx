import {
  Download,
  GitHub,
  Group,
  LinkedIn,
  Mail,
  Phone,
} from "@mui/icons-material";
import {
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
  Menu,
  MenuItem,
  Stack,
  Typography,
} from "@mui/material";
import { CopyButton } from "../../components/CopyButton";
import { useRef, useState } from "react";

export function GetInTouchCard(): React.ReactElement {
  const [isDownloadMenuOpen, setIsDownloadMenuOpen] = useState(false);
  const downloadMenuAnchorRef = useRef(null);
  return (
    <Card elevation={10}>
      <CardContent>
        <Stack spacing={1}>
          <Typography
            variant="h5"
            sx={{ fontWeight: 600, whiteSpace: "nowrap" }}
          >
            Get In Touch
          </Typography>
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
                primary={<Link href="tel:+15129099300">+1-512-909-9300</Link>}
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
                <Stack
                  direction="row"
                  spacing={1}
                  alignItems={"center"}
                  justifyContent={"center"}
                >
                  <Link
                    href="https://www.linkedin.com/in/samantha-hughes-2b8b7716"
                    target="_blank"
                    rel="noreferrer"
                    sx={{ display: "flex", alignItems: "center" }}
                  >
                    <LinkedIn htmlColor="rgb(7, 98, 200)" />
                  </Link>
                  <Link
                    href="https://github.com/shughes-uk"
                    target="_blank"
                    rel="noreferrer"
                    sx={{ display: "flex", alignItems: "center" }}
                  >
                    <GitHub htmlColor="black" />
                  </Link>
                </Stack>
              </ListItemIcon>
            </ListItem>
          </List>
          <Button
            size="small"
            variant="outlined"
            ref={downloadMenuAnchorRef}
            onClick={() => setIsDownloadMenuOpen(true)}
          >
            Download Resume
          </Button>
          <Menu
            open={isDownloadMenuOpen}
            onClose={() => setIsDownloadMenuOpen(false)}
            anchorOrigin={{
              vertical: "bottom",
              horizontal: "left",
            }}
            transformOrigin={{
              vertical: "top",
              horizontal: "left",
            }}
            anchorEl={downloadMenuAnchorRef.current}
            keepMounted
          >
            <MenuItem
              component={Link}
              href={"/Samantha_Hughes_Resume.docx"}
              download
              target="_blank"
              onClick={() => setIsDownloadMenuOpen(false)}
            >
              <ListItemIcon>
                <Download />
              </ListItemIcon>
              <ListItemText primary="Microsoft Word (.docx)" />
            </MenuItem>
            <MenuItem
              component={Link}
              href={"/Samantha_Hughes_Resume.pdf"}
              download
              target="_blank"
              onClick={() => setIsDownloadMenuOpen(false)}
            >
              <ListItemIcon>
                <Download />
              </ListItemIcon>
              <ListItemText primary="PDF Document (.pdf)" />
            </MenuItem>
          </Menu>
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
  );
}
