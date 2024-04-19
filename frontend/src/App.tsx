import { GitHub } from "@mui/icons-material";
import { Link, Tooltip } from "@mui/material";
import { useLocalStorage } from "usehooks-ts";
import { useEffect } from "react";
import { Outlet } from "react-router-dom";
import { AuthProvider } from "./components/providers/auth";

function App() {
  const [hasSeenSourceTooltip, setHasSeenSourceTooltip] =
    useLocalStorage<boolean>("hasSeenSourceTooltip", false);
  useEffect(() => {
    if (!hasSeenSourceTooltip) {
      setTimeout(() => {
        setHasSeenSourceTooltip(true);
      }, 5000);
    }
  });
  return (
    <AuthProvider>
      <Outlet />
      <Link component={Link} href="https://github.com/shughes-uk/resume">
        <Tooltip
          open={hasSeenSourceTooltip ? undefined : true}
          title="Explore this project on GitHub!"
          arrow
        >
          <GitHub
            htmlColor="black"
            sx={{
              position: "fixed",
              bottom: "20px",
              right: "20px",
              zIndex: 9999,
            }}
          />
        </Tooltip>
      </Link>
    </AuthProvider>
  );
}

export default App;
